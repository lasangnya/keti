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
import 'package:keti/presentation/pages/study/study_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../application/study/session_test_fakes.dart';

void main() {
  late Directory csvRoot;
  late DateTime fakeNow;
  late List<String> launchedUrls;

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
  }) async {
    SharedPreferences.setMockInitialValues({});
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
              .overrideWithValue(MockParticipantRepository()),
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

  testWidgets('day 1 completion shows and launches the end-of-day form',
      (tester) async {
    final container = await pumpStudyPage(tester);
    await enterCode(tester, 'P001');
    await driveDayToCompletion(tester, container, 'Start Day 1');

    expect(find.text('Day 1 complete'), findsOneWidget);
    expect(find.text('Complete end of day questionnaire'), findsOneWidget);
    expect(find.text('Complete final questionnaire'), findsNothing);

    await tester.tap(find.text('Complete end of day questionnaire'));
    await tester.pumpAndSettle();

    expect(launchedUrls, hasLength(1));
    expect(
      launchedUrls.single,
      'https://docs.google.com/forms/d/e/example/viewform'
      '?usp=pp_url&entry.10=P001&entry.11=day1',
    );
  });

  testWidgets('day 2 completion offers the final questionnaire too',
      (tester) async {
    final container = await pumpStudyPage(tester);
    await enterCode(tester, 'P002');
    await driveDayToCompletion(tester, container, 'Start Day 2');

    expect(find.text('Day 2 complete'), findsOneWidget);
    expect(find.text('Complete end of day questionnaire'), findsOneWidget);
    expect(find.text('Complete final questionnaire'), findsOneWidget);

    await tester.tap(find.text('Complete final questionnaire'));
    await tester.pumpAndSettle();

    expect(launchedUrls, hasLength(1));
    expect(launchedUrls.single, contains('entry.10=P002'));
  });

}
