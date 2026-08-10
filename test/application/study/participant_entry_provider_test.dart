import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/application/study/participant_entry_provider.dart';
import 'package:keti/application/study/participant_providers.dart';
import 'package:keti/core/services/local/csv_store.dart';
import 'package:keti/core/services/local/local_store.dart';
import 'package:keti/core/services/study/mock_participant_repository.dart';
import 'package:keti/domain/study/day_schedule.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_config.dart';
import 'package:keti/domain/study/study_enums.dart';
import 'package:keti/domain/study/study_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/firebase_mock.dart';

void main() {
  late Directory csvRoot;
  late ProviderContainer container;

  setUpAll(initFirebaseForTest);

  setUp(() async {
    csvRoot = Directory.systemTemp.createTempSync('keti_entry_test');
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore(await SharedPreferences.getInstance());
    container = ProviderContainer(overrides: [
      participantRepositoryProvider
          .overrideWithValue(MockParticipantRepository()),
      localStoreProvider.overrideWith((ref) async => store),
      csvStoreProvider.overrideWithValue(CsvStore(rootDir: csvRoot)),
    ]);
    addTearDown(container.dispose);
  });

  tearDown(() {
    if (csvRoot.existsSync()) csvRoot.deleteSync(recursive: true);
  });

  test('enterCode reports a completed day without hanging', () async {
    await CsvStore(rootDir: csvRoot).writeSession(
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

    await container
        .read(participantEntryProvider.notifier)
        .enterCode('P002');

    final state = container.read(participantEntryProvider);
    expect(state.isReady, isTrue);
    expect(state.dayAlreadyCompleted, isTrue);
    expect(state.errorMessage, 'Day 2 is already completed for P002.');
  });
}
