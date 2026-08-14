import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/application/reminders/reminder_orchestrator.dart';
import 'package:keti/application/study/participant_entry_provider.dart';
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

import '../../../application/study/session_test_fakes.dart';
import '../../../helpers/firebase_mock.dart';

void main() {
  late Directory csvRoot;

  setUpAll(initFirebaseForTest);

  setUp(() {
    csvRoot = Directory.systemTemp.createTempSync('keti_widget_test');
  });

  tearDown(() {
    if (csvRoot.existsSync()) csvRoot.deleteSync(recursive: true);
  });

  Future<LocalStore> mockLocalStore({
    Map<String, Object> initial = const {},
    bool tutorialSeen = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (tutorialSeen) ...{
        'tutorial.seen.P001': true,
        'tutorial.seen.P002': true,
      },
      ...initial,
    });
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

  /// Advances the tutorial from Welcome to the Participant-ID step.
  Future<void> continueWelcome(WidgetTester tester) async {
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  Future<void> enterCodeAndContinue(WidgetTester tester, String code) async {
    await continueWelcome(tester);
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
  }

  group('tutorial flow', () {
    testWidgets('welcome shows first, then the participant ID step',
        (tester) async {
      await pumpStudyPage(tester);
      expect(find.text('Welcome to the health-reminder study'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await continueWelcome(tester);
      expect(find.text('Enter your Participant ID'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('blank ID shows the doc-exact validation message',
        (tester) async {
      await pumpStudyPage(tester);
      await continueWelcome(tester);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(
        find.text("Please enter the Participant ID provided by the researcher. "
            "It starts with the letter 'P'"),
        findsOneWidget,
      );
    });

    testWidgets('invalid code shows a validation error without fetching',
        (tester) async {
      await pumpStudyPage(tester);
      await enterCodeAndContinue(tester, 'xyz');
      expect(find.textContaining('valid participant ID'), findsOneWidget);
    });

    testWidgets('unknown code shows a not-found error', (tester) async {
      await pumpStudyPage(tester);
      await enterCodeAndContinue(tester, 'P099');
      expect(find.text('Unknown participant code P099.'), findsOneWidget);
    });

    testWidgets('first-time participant walks the full tutorial to Start session',
        (tester) async {
      await pumpStudyPage(tester);
      await enterCodeAndContinue(tester, 'P001');

      // After a valid ID the wizard continues into the info steps.
      expect(find.text('Prepare for your session'), findsOneWidget);
      await tester.ensureVisible(find.text('I have completed the pre-study questionnaire'));
      await tester.tap(find.text('I have completed the pre-study questionnaire'));
      await tester.pumpAndSettle();
      expect(find.text('Work as you normally would'), findsOneWidget);
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Respond naturally'), findsOneWidget);
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.textContaining('dismiss a reminder quickly'), findsOneWidget);
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Your comfort comes first'), findsOneWidget);
      await tester.ensureVisible(find.text('Next'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('At the end of the session'), findsOneWidget);

      // Starting the session from the tutorial lands in the session view.
      await tester.ensureVisible(find.text('Start session'));
      await tester.tap(find.text('Start session'));
      await tester.pumpAndSettle();
      expect(find.text('Session active — Day 1'), findsOneWidget);
    });

    testWidgets('Back walks the tutorial to any previous step', (tester) async {
      await pumpStudyPage(tester);

      // First step has no Back.
      expect(find.text('Back'), findsNothing);
      await continueWelcome(tester);
      expect(find.text('Back'), findsOneWidget);

      // Back from the ID step returns to Welcome.
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to the health-reminder study'), findsOneWidget);

      // Forward again, submit a code, then Back from Prepare returns to the
      // ID step with the entered code still in the field.
      await continueWelcome(tester);
      await tester.enterText(find.byType(TextField), 'P001');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Prepare for your session'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your Participant ID'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'P001');
    });

    testWidgets('Back to the ID step allows changing the participant code',
        (tester) async {
      await pumpStudyPage(tester);
      await enterCodeAndContinue(tester, 'P001');
      expect(find.text('Prepare for your session'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'P002');
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // The re-submitted code replaces the first participant.
      expect(find.text('Prepare for your session'), findsOneWidget);
      final container =
          ProviderScope.containerOf(tester.element(find.byType(StudyPage)));
      expect(
        container.read(participantEntryProvider).participant!.participantCode,
        'P002',
      );
    });

    testWidgets('tutorial is skipped once seen — straight to day overview',
        (tester) async {
      final store = await mockLocalStore(tutorialSeen: true);
      await pumpStudyPage(tester, localStore: store);
      await enterCodeAndContinue(tester, 'P001');
      expect(find.text('Start Day 1'), findsOneWidget);
    });
  });

  group('day overview & session', () {
    testWidgets('valid code shows the day overview for the active day',
        (tester) async {
      final store = await mockLocalStore(tutorialSeen: true);
      await pumpStudyPage(tester, localStore: store);
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
      final store = await mockLocalStore(initial: {'lastParticipantCode': 'P001'});
      await pumpStudyPage(tester, localStore: store);
      await continueWelcome(tester);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'P001');
    });

    testWidgets('completed day shows the completed view with stored ID',
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

      final store = await mockLocalStore(tutorialSeen: true);
      await pumpStudyPage(tester, localStore: store);
      await enterCodeAndContinue(tester, 'P002');
      expect(find.text('Study complete'), findsOneWidget);
      expect(find.text('Your Participant ID: P002'), findsOneWidget);
      expect(find.text('Open Session 2 End-of-Session Questionnaire'),
          findsOneWidget);
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

      final store = await mockLocalStore(tutorialSeen: true);
      await pumpStudyPage(tester, localStore: store);
      await enterCodeAndContinue(tester, 'P001');
      expect(find.text('Unfinished session found on this machine'),
          findsOneWidget);
    });

    testWidgets('provider falls back to the cache when the network fails',
        (tester) async {
      // A repository that simulates being offline.
      final offlineRepo = _OfflineRepository();
      final store = await mockLocalStore(tutorialSeen: true);
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
      final store = await mockLocalStore(tutorialSeen: true);
      await pumpStudyPage(tester, localStore: store);
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

      final store = await mockLocalStore(tutorialSeen: true);
      await pumpStudyPage(tester, localStore: store);
      await enterCodeAndContinue(tester, 'P001');
      await tester.ensureVisible(find.text('Resume Day 1'));
      await tester.tap(find.text('Resume Day 1'));
      await tester.pumpAndSettle();

      expect(find.text('Session active — Day 1'), findsOneWidget);
    });
  });
}

class _OfflineRepository extends MockParticipantRepository {
  @override
  Future<Participant> fetchParticipant(String code) =>
      throw const SocketException('offline');
}
