import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/application/study/participant_providers.dart';
import 'package:keti/application/study/scheduler_provider.dart';
import 'package:keti/core/services/firebase/firestore_providers.dart';
import 'package:keti/core/services/local/csv_store.dart';
import 'package:keti/core/services/local/local_store.dart';
import 'package:keti/core/services/study/mock_participant_repository.dart';
import 'package:keti/domain/study/day_schedule.dart';
import 'package:keti/domain/study/participant.dart';
import 'package:keti/domain/study/reminder_event.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_config.dart';
import 'package:keti/domain/study/study_enums.dart';
import 'package:keti/domain/study/study_session.dart';
import 'package:keti/presentation/pages/study/study_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:keti/application/reminders/reminder_orchestrator.dart';

import '../../../application/study/session_test_fakes.dart';

void main() {
  late Directory csvRoot;

  setUp(() {
    csvRoot = Directory.systemTemp.createTempSync('keti_widget_test');
  });

  tearDown(() {
    if (csvRoot.existsSync()) csvRoot.deleteSync(recursive: true);
  });

  Future<LocalStore> mockLocalStore([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    return LocalStore(await SharedPreferences.getInstance());
  }

  Future<void> pumpStudyPage(
    WidgetTester tester, {
    LocalStore? localStore,
    MockParticipantRepository? repository,
  }) async {
    final store = localStore ?? await mockLocalStore();
    // Native channels under test: answer session-lifecycle calls with null.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('app.keti/session_lifecycle'),
      (call) async => null,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          participantRepositoryProvider
              .overrideWithValue(repository ?? MockParticipantRepository()),
          localStoreProvider.overrideWith((ref) async => store),
          csvStoreProvider.overrideWithValue(CsvStore(rootDir: csvRoot)),
          sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
          reminderEventRepositoryProvider
              .overrideWithValue(FakeEventRepository()),
          reminderOrchestratorProvider.overrideWithValue(FakeReminderOrchestrator()),
          studyClockProvider.overrideWithValue(
              () => DateTime.parse('2026-08-03T09:00:00+02:00')),
          schedulerTickIntervalProvider
              .overrideWithValue(const Duration(days: 365)),
        ],
        child: const MaterialApp(home: Scaffold(body: StudyPage())),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterCodeAndContinue(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  testWidgets('invalid code shows a validation error without fetching',
      (tester) async {
    await pumpStudyPage(tester);
    await enterCodeAndContinue(tester, 'xyz');
    expect(find.textContaining('valid participant code'), findsOneWidget);
  });

  testWidgets('unknown code shows a not-found error', (tester) async {
    await pumpStudyPage(tester);
    await enterCodeAndContinue(tester, 'P099');
    expect(find.text('Unknown participant code P099.'), findsOneWidget);
  });

  testWidgets('valid code shows the day overview for the active day',
      (tester) async {
    await pumpStudyPage(tester);
    await enterCodeAndContinue(tester, 'P001');

    expect(find.text('P001'), findsOneWidget);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Start Day 1'), findsOneWidget);

    // P002 is activated for day 2 in the mock and gets the character style.
    await tester.tap(find.text('Use a different code'));
    await tester.pumpAndSettle();
    await enterCodeAndContinue(tester, 'P002');
    expect(find.text('P002'), findsOneWidget);
    expect(find.text('Day 2'), findsOneWidget);
  });

  testWidgets('last used code is pre-filled into the text field',
      (tester) async {
    final store = await mockLocalStore({'lastParticipantCode': 'P001'});
    await pumpStudyPage(tester, localStore: store);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'P001');
  });

  testWidgets('completed day is reported and cannot be started again',
      (tester) async {
    // Pre-write a completed day2 session for P002 into the CSV store.
    final csv = CsvStore(rootDir: csvRoot);
    await csv.writeSession(
      StudySession(
        participantCode: 'P002',
        dayNumber: 2,
        style: PresentationStyle.ambient,
        status: StudySessionStatus.completed,
        startedAtLocal: DateTime.parse('2026-08-04T09:00:00+02:00'),
        completedAtLocal: DateTime.parse('2026-08-04T11:00:00+02:00'),
        schedule: const DaySchedule(
          dayNumber: 2,
          style: PresentationStyle.ambient,
          reminders: kDefaultScheduleTemplate,
        ),
        links: const QuestionnaireLinks(),
      ),
    );

    await pumpStudyPage(tester);
    await enterCodeAndContinue(tester, 'P002');
    expect(find.text('Day 2 is already completed for P002.'), findsOneWidget);
  });

  testWidgets('unfinished local session surfaces the resume banner',
      (tester) async {
    final csv = CsvStore(rootDir: csvRoot);
    await csv.writeSession(
      StudySession(
        participantCode: 'P001',
        dayNumber: 1,
        style: PresentationStyle.ambient,
        status: StudySessionStatus.active,
        startedAtLocal: DateTime.parse('2026-08-03T09:00:00+02:00'),
        schedule: const DaySchedule(
          dayNumber: 1,
          style: PresentationStyle.ambient,
          reminders: kDefaultScheduleTemplate,
        ),
        links: const QuestionnaireLinks(),
      ),
    );

    await pumpStudyPage(tester);
    await enterCodeAndContinue(tester, 'P001');
    expect(find.text('Unfinished session found on this machine'),
        findsOneWidget);
  });

  testWidgets('provider falls back to the cache when the network fails',
      (tester) async {
    // A repository that simulates being offline.
    final offlineRepo = _OfflineRepository();
    final store = await mockLocalStore();
    // Prime the cache as if P001 had been loaded before.
    final participant =
        MockParticipantRepository.defaultParticipants['P001']!;
    await store.cacheParticipant(participant);
    await store.cacheStudyConfig(MockParticipantRepository.config);
    await store.cacheScheduleFor(
      'P001',
      const DaySchedule(
        dayNumber: 1,
        style: PresentationStyle.ambient,
        reminders: kDefaultScheduleTemplate,
      ),
    );

    await pumpStudyPage(tester, localStore: store, repository: offlineRepo);
    await enterCodeAndContinue(tester, 'P001');
    expect(find.text('P001'), findsOneWidget);
    expect(find.text('Loaded from local cache (offline)'), findsOneWidget);
  });

  testWidgets('Start Day begins the session and shows the event list',
      (tester) async {
    await pumpStudyPage(tester);
    await enterCodeAndContinue(tester, 'P001');
    await tester.ensureVisible(find.text('Start Day 1'));
    await tester.tap(find.text('Start Day 1'));
    await tester.pumpAndSettle();

    expect(find.text('Session active — Day 1'), findsOneWidget);
    expect(find.text('Reminder 1'), findsOneWidget);
    expect(find.text('Reminder 8'), findsOneWidget);
    expect(find.text('SCHEDULED'), findsNWidgets(8));
  });

  testWidgets('Resume button resumes an unfinished session', (tester) async {
    final csv = CsvStore(rootDir: csvRoot);
    final start = DateTime.parse('2026-08-03T09:00:00+02:00');
    await csv.writeSession(
      StudySession(
        participantCode: 'P001',
        dayNumber: 1,
        style: PresentationStyle.ambient,
        status: StudySessionStatus.active,
        startedAtLocal: start,
        schedule: const DaySchedule(
          dayNumber: 1,
          style: PresentationStyle.ambient,
          reminders: kDefaultScheduleTemplate,
        ),
        links: const QuestionnaireLinks(),
      ),
    );
    await csv.writeEvents(
      'P001',
      'day1',
      [
        for (final reminder in kDefaultScheduleTemplate)
          ReminderEvent.scheduled(
            participantCode: 'P001',
            dayNumber: 1,
            reminder: reminder,
            style: PresentationStyle.ambient,
            sessionStartLocal: start,
            environment: 'dev',
            appVersion: '1.0.0+1',
            protocolVersion: '2026-08-v1',
          ),
      ],
    );

    await pumpStudyPage(tester);
    await enterCodeAndContinue(tester, 'P001');
    await tester.ensureVisible(find.text('Resume Day 1'));
    await tester.tap(find.text('Resume Day 1'));
    await tester.pumpAndSettle();

    expect(find.text('Session active — Day 1'), findsOneWidget);
  });
}

class _OfflineRepository extends MockParticipantRepository {
  @override
  Future<Participant> fetchParticipant(String code) =>
      throw const SocketException('offline');
}
