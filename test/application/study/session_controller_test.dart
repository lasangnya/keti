import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/application/study/participant_entry_provider.dart';
import 'package:keti/application/study/participant_providers.dart';
import 'package:keti/application/study/scheduler_provider.dart';
import 'package:keti/application/study/session_controller.dart';
import 'package:keti/core/services/firebase/firestore_providers.dart';
import 'package:keti/core/services/local/csv_store.dart';
import 'package:keti/core/services/local/local_store.dart';
import 'package:keti/core/services/study/mock_participant_repository.dart';
import 'package:keti/domain/study/study_enums.dart';
import 'package:keti/domain/study/study_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:keti/application/reminders/reminder_orchestrator.dart';

import 'session_test_fakes.dart';

void main() {
  // The session controller invokes the session-lifecycle MethodChannel.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory csvRoot;
  late DateTime fakeNow;
  late FakeSessionRepository sessionRepo;
  late FakeEventRepository eventRepo;
  late FakeReminderOrchestrator orchestrator;

  setUp(() {
    csvRoot = Directory.systemTemp.createTempSync('keti_m4_test');
    fakeNow = DateTime.parse('2026-08-03T09:00:00+02:00');
    sessionRepo = FakeSessionRepository();
    eventRepo = FakeEventRepository();
    orchestrator = FakeReminderOrchestrator();
  });

  tearDown(() {
    if (csvRoot.existsSync()) csvRoot.deleteSync(recursive: true);
  });

  Future<ProviderContainer> createContainer() async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    final container = ProviderContainer(overrides: [
      participantRepositoryProvider
          .overrideWithValue(MockParticipantRepository()),
      localStoreProvider.overrideWith((ref) async => store),
      csvStoreProvider.overrideWithValue(CsvStore(rootDir: csvRoot)),
      sessionRepositoryProvider.overrideWithValue(sessionRepo),
      reminderEventRepositoryProvider.overrideWithValue(eventRepo),
      reminderOrchestratorProvider.overrideWithValue(orchestrator),
      studyClockProvider.overrideWithValue(() => fakeNow),
      schedulerTickIntervalProvider
          .overrideWithValue(const Duration(days: 365)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Future<ProviderContainer> startedContainer() async {
    final container = await createContainer();
    await container.read(participantEntryProvider.notifier).enterCode('P001');
    await container.read(sessionControllerProvider.notifier).startDay();
    return container;
  }

  group('startDay', () {
    test('creates session + 8 scheduled events in CSV and Firestore',
        () async {
      final container = await startedContainer();
      final state = container.read(sessionControllerProvider);

      expect(state.active, isTrue);
      expect(state.events, hasLength(8));
      expect(
        state.events
            .every((e) => e.deliveryStatus == DeliveryStatus.scheduled),
        isTrue,
      );
      expect(
          state.nextFireTime, DateTime.parse('2026-08-03T09:20:00+02:00'));

      // CSV ground truth.
      final csv = CsvStore(rootDir: csvRoot);
      final session = await csv.readSession('P001', 'day1');
      expect(session!.status, StudySessionStatus.active);
      expect(session.style, PresentationStyle.ambient); // P001 = ambient first
      final events = await csv.readEvents('P001', 'day1');
      expect(events, hasLength(8));

      // Firestore writes happened once each.
      expect(sessionRepo.createCalls, 1);
      expect(eventRepo.createCalls, 1);
      expect(eventRepo.created, hasLength(8));
    });

    test('sets the active-session pointer used for resume', () async {
      final container = await startedContainer();
      final store = await container.read(localStoreProvider.future);
      expect(store.readActiveSession('P001'), 'day1');
      expect(store.lastParticipantCode, 'P001');
    });
  });

  group('delivery', () {
    test('due reminder is delivered with zero lateness on the dot', () async {
      final container = await startedContainer();
      fakeNow = DateTime.parse('2026-08-03T09:20:00+02:00');
      await container.read(sessionControllerProvider.notifier).debugTick();
      await container.read(sessionControllerProvider.notifier).debugAwaitIdle();

      expect(orchestrator.calls, hasLength(1));
      expect(orchestrator.calls.single.placement, Placement.cursorProximate);
      expect(orchestrator.calls.single.content.message, 'Stay hydrated');

      final state = container.read(sessionControllerProvider);
      final event = state.events.firstWhere((e) => e.reminderNumber == 1);
      expect(event.deliveryStatus, DeliveryStatus.delivered);
      expect(event.deliveryLatenessMs, 0);
      // The full chain persisted: delivered → hidden → card shown → answered.
      expect(
        eventRepo.updated
            .map((e) => e.deliveryStatus)
            .contains(DeliveryStatus.delivered),
        isTrue,
      );
      expect(event.outcome, ResponseOutcome.completed);
      expect(event.cardShownAtLocal, isNotNull);
    });

    test('within grace records lateness; past grace is suppressed', () async {
      final container = await startedContainer();

      // 90s late → delivered with lateness.
      fakeNow = DateTime.parse('2026-08-03T09:21:30+02:00');
      await container.read(sessionControllerProvider.notifier).debugTick();
      await container.read(sessionControllerProvider.notifier).debugAwaitIdle();
      var state = container.read(sessionControllerProvider);
      expect(
        state.events.firstWhere((e) => e.reminderNumber == 1).deliveryStatus,
        DeliveryStatus.delivered,
      );
      expect(
        state.events
            .firstWhere((e) => e.reminderNumber == 1)
            .deliveryLatenessMs,
        90000,
      );

      // Reminder 2 (09:30) checked at 09:32:01 → past the 120 s grace.
      // The >10 s tick gap makes this a stalled-tick miss (device_inactive);
      // late_delivery is reserved for app-alive lateness (display queue, M5).
      fakeNow = DateTime.parse('2026-08-03T09:32:01+02:00');
      await container.read(sessionControllerProvider.notifier).debugTick();
      await container.read(sessionControllerProvider.notifier).debugAwaitIdle();
      state = container.read(sessionControllerProvider);
      final missed = state.events.firstWhere((e) => e.reminderNumber == 2);
      expect(missed.deliveryStatus, DeliveryStatus.suppressed);
      expect(missed.suppressionReason, 'device_inactive');
      expect(orchestrator.calls, hasLength(1)); // nothing new shown
    });

    test('display failure marks the event failed and continues', () async {
      final container = await startedContainer();
      orchestrator.failNext = true;
      fakeNow = DateTime.parse('2026-08-03T09:20:00+02:00');
      await container.read(sessionControllerProvider.notifier).debugTick();
      await container.read(sessionControllerProvider.notifier).debugAwaitIdle();

      final event = container
          .read(sessionControllerProvider)
          .events
          .firstWhere((e) => e.reminderNumber == 1);
      expect(event.deliveryStatus, DeliveryStatus.failed);
      expect(event.failureReason, contains('display_dispatch'));
    });
  });
}
