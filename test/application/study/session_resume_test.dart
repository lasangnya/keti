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
    csvRoot = Directory.systemTemp.createTempSync('keti_m4_resume_test');
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

  group('resume', () {
    test('kill at 00:25 → resume re-anchors, marks missed, no duplicates',
        () async {
      // Start at 09:00, then "kill" the app (container disposed).
      final first = await startedContainer();
      first.dispose();

      // Relaunch at 09:25: reminder 1 (09:20) is past the grace window.
      fakeNow = DateTime.parse('2026-08-03T09:25:00+02:00');
      final container = await createContainer();
      await container
          .read(participantEntryProvider.notifier)
          .enterCode('P001');

      final resumed = await container
          .read(sessionControllerProvider.notifier)
          .resumeActiveSession();
      expect(resumed, isTrue);

      final state = container.read(sessionControllerProvider);
      expect(state.active, isTrue);
      expect(state.session!.resumedCount, 1);

      final missed = state.events.firstWhere((e) => e.reminderNumber == 1);
      expect(missed.deliveryStatus, DeliveryStatus.notDisplayed);
      expect(missed.suppressionReason, 'app_terminated');

      // Pending events flagged as post-resume; no duplicate remote creation.
      expect(
        state.events
            .where((e) => e.deliveryStatus == DeliveryStatus.scheduled)
            .every((e) => e.sessionResumed),
        isTrue,
      );
      expect(sessionRepo.createCalls, 1); // only the initial start created
      expect(sessionRepo.resumeCalls, 1);
      expect(eventRepo.createCalls, 1); // same: no duplicate event creation

      // Reminder 2 still arrives on time after the resume.
      fakeNow = DateTime.parse('2026-08-03T09:30:00+02:00');
      await container.read(sessionControllerProvider.notifier).debugTick();
      await container.read(sessionControllerProvider.notifier).debugAwaitIdle();
      expect(orchestrator.calls, hasLength(1));
      final second = container
          .read(sessionControllerProvider)
          .events
          .firstWhere((e) => e.reminderNumber == 2);
      expect(second.deliveryStatus, DeliveryStatus.delivered);
      expect(second.sessionResumed, isTrue);

      // CSV reflects everything.
      final csvSession =
          await CsvStore(rootDir: csvRoot).readSession('P001', 'day1');
      expect(csvSession!.resumedCount, 1);
    });

    test('returns false when there is nothing to resume', () async {
      final container = await createContainer();
      await container
          .read(participantEntryProvider.notifier)
          .enterCode('P001');
      final resumed = await container
          .read(sessionControllerProvider.notifier)
          .resumeActiveSession();
      expect(resumed, isFalse);
    });
  });

  group('completion', () {
    test('day completes when all 8 events are finalized', () async {
      final container = await startedContainer();

      // Jump straight to the last fire time: 1–7 are past grace (missed),
      // 8 is due exactly on time (delivered).
      fakeNow = DateTime.parse('2026-08-03T10:40:00+02:00');
      await container.read(sessionControllerProvider.notifier).debugTick();
      await container.read(sessionControllerProvider.notifier).debugAwaitIdle();

      final state = container.read(sessionControllerProvider);
      expect(state.completed, isTrue);
      expect(state.active, isFalse);
      expect(state.session!.status, StudySessionStatus.completed);
      expect(
        state.events
            .every((e) => e.deliveryStatus != DeliveryStatus.scheduled),
        isTrue,
      );
      expect(orchestrator.calls, hasLength(1)); // only reminder 8 was shown

      expect(sessionRepo.completeCalls, 1);

      // Session CSV completed and the resume pointer cleared.
      final csvSession =
          await CsvStore(rootDir: csvRoot).readSession('P001', 'day1');
      expect(csvSession!.status, StudySessionStatus.completed);
      final store = await container.read(localStoreProvider.future);
      expect(store.readActiveSession('P001'), isNull);
    });
  });
}
