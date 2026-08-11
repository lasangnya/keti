import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/application/reminders/reminder_orchestrator.dart';
import 'package:keti/application/study/participant_providers.dart';
import 'package:keti/application/study/scheduler_provider.dart';
import 'package:keti/application/study/session_controller.dart';
import 'package:keti/core/services/firebase/firestore_providers.dart';
import 'package:keti/core/services/local/csv_store.dart';
import 'package:keti/core/services/local/local_store.dart';
import 'package:keti/core/services/study/mock_participant_repository.dart';
import 'package:keti/domain/study/participant.dart';
import 'package:keti/presentation/pages/study/study_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../application/study/session_test_fakes.dart';
import '../../../helpers/firebase_mock.dart';

void main() {
  late Directory csvRoot;
  late DateTime fakeNow;
  late List<String> launchedUrls;

  setUpAll(initFirebaseForTest);

  setUp(() {
    csvRoot = Directory.systemTemp.createTempSync('keti_m6_test');
    fakeNow = DateTime.parse('2026-08-03T09:00:00+02:00');
    launchedUrls = [];
  });

  tearDown(() {
    if (csvRoot.existsSync()) csvRoot.deleteSync(recursive: true);
  });

  Future<ProviderContainer> pumpStudyPage(
    WidgetTester tester, {
    FakeReminderOrchestrator? orchestrator,
    MockParticipantRepository? repository,
  }) async {
    SharedPreferences.setMockInitialValues({
      'tutorial.seen.P001': true,
      'tutorial.seen.P002': true,
    });
    final store = LocalStore(await SharedPreferences.getInstance());

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('app.keti/session_lifecycle'),
      (call) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async {
        if (call.method == 'launch') {
          launchedUrls.add((call.arguments as Map)['url'] as String);
        }
        return true;
      },
    );

    late ProviderContainer container;
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
          reminderOrchestratorProvider
              .overrideWithValue(orchestrator ?? FakeReminderOrchestrator()),
          studyClockProvider.overrideWithValue(() => fakeNow),
          schedulerTickIntervalProvider
              .overrideWithValue(const Duration(days: 365)),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const Scaffold(body: StudyPage());
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
  }

  Future<void> driveDayToCompletion(
      WidgetTester tester, ProviderContainer container, String startLabel) async {
    await tester.ensureVisible(find.text(startLabel));
    await tester.tap(find.text(startLabel));
    await tester.pumpAndSettle();

    // Jump to the last fire time and let the chain finish.
    fakeNow = DateTime.parse('2026-08-03T10:40:00+02:00');
    await container.read(sessionControllerProvider.notifier).debugTick();
    await container.read(sessionControllerProvider.notifier).debugAwaitIdle();
    await tester.pumpAndSettle();
  }

  testWidgets(
      'day 1 completion shows session 1 form and Start Day 2 (locked until activated)',
      (tester) async {
    final container = await pumpStudyPage(tester);
    await enterCode(tester, 'P001');
    await driveDayToCompletion(tester, container, 'Start Day 1');

    // Completed view with the stored ID and the session-1 end-of-session form.
    expect(find.text('Session complete'), findsOneWidget);
    expect(find.text('Your Participant ID: P001'), findsOneWidget);
    expect(find.text('Open Session 1 End-of-Session Questionnaire'),
        findsOneWidget);
    expect(find.text('Open Session 2 End-of-Session Questionnaire'),
        findsNothing);
    expect(find.text('Open End-of-Study Questionnaire'), findsNothing);

    await tester.tap(find.text('Open Session 1 End-of-Session Questionnaire'));
    await tester.pumpAndSettle();

    expect(launchedUrls, hasLength(1));
    expect(
      launchedUrls.single,
      'https://docs.google.com/forms/d/e/example/viewform'
      '?usp=pp_url&entry.10=P001&entry.11=ambient',
    );

    // Start Day 2 is offered immediately; P001 is not day-2 activated in the
    // mock → button disabled + hint.
    expect(find.text('Start Day 2'), findsOneWidget);
    final startDay2 = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Start Day 2'),
    );
    expect(startDay2.onPressed, isNull);
    expect(find.textContaining('has not been activated'), findsOneWidget);
  });

  testWidgets('day 2 completion reveals the end-of-study questionnaire',
      (tester) async {
    final container = await pumpStudyPage(tester);
    await enterCode(tester, 'P002');
    await driveDayToCompletion(tester, container, 'Start Day 2');

    expect(find.text('Study complete'), findsOneWidget);
    expect(find.text('Your Participant ID: P002'), findsOneWidget);
    expect(find.text('Open Session 2 End-of-Session Questionnaire'),
        findsOneWidget);

    // With both sessions complete the final questionnaire is offered right away.
    expect(find.text('Open End-of-Study Questionnaire'), findsOneWidget);

    await tester.tap(find.text('Open End-of-Study Questionnaire'));
    await tester.pumpAndSettle();

    expect(launchedUrls, hasLength(1));
    expect(launchedUrls.single, contains('entry.10=P002'));
  });

  testWidgets('Start Day 2 loads the day-2 overview, not the tutorial',
      (tester) async {
    // Repository that starts on day 1 and flips to day 2 when the
    // researcher "activates" it.
    final repo = _ActivatingRepository();
    final container = await pumpStudyPage(tester, repository: repo);
    await enterCode(tester, 'P001');
    await driveDayToCompletion(tester, container, 'Start Day 1');

    // Researcher activates Day 2 → participant re-checks and the button
    // becomes enabled.
    repo.day2Activated = true;
    await tester.ensureVisible(find.text('Check again'));
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Start Day 2'));
    await tester.tap(find.text('Start Day 2'));
    await tester.pumpAndSettle();

    // Lands on the Day 2 overview — never the tutorial welcome.
    expect(find.text('Welcome to the health-reminder study'), findsNothing);
    expect(find.text('P001'), findsOneWidget);
    expect(find.text('Day 2'), findsOneWidget);
    expect(find.text('Start Day 2'), findsOneWidget);
  });
}

/// Mock repo whose participants flip to day 2 once the researcher activates
/// it (mirrors the admin "Activate Day 2" action).
class _ActivatingRepository extends MockParticipantRepository {
  bool day2Activated = false;

  @override
  Future<Participant> fetchParticipant(String code) async {
    final p = await super.fetchParticipant(code);
    if (!day2Activated || p.participantCode != 'P001') return p;
    return Participant(
      participantCode: p.participantCode,
      serial: p.serial,
      styleOrder: p.styleOrder,
      assignmentOverride: p.assignmentOverride,
      activeDay: 2,
      environment: p.environment,
      protocolVersion: p.protocolVersion,
    );
  }
}
