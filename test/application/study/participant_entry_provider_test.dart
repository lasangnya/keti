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
    // A completed day is a normal state (shown via the completed view),
    // not an error message — errorMessage stays null so stale text never
    // leaks into unrelated UI (e.g. the Start Day 2 snackbar).
    expect(state.errorMessage, isNull);
  });

  test('enterCode forces the requested day number on a corrupt schedule doc',
      () async {
    // Simulates the real-world bug: the day-2 schedule document exists but
    // carries dayNumber 1 (fromJson would otherwise resolve it as day 1).
    container = ProviderContainer(overrides: [
      participantRepositoryProvider
          .overrideWithValue(_CorruptDayNumberRepository()),
      localStoreProvider.overrideWith(
          (ref) async => LocalStore(await SharedPreferences.getInstance())),
      csvStoreProvider.overrideWithValue(CsvStore(rootDir: csvRoot)),
    ]);
    addTearDown(container.dispose);

    await container
        .read(participantEntryProvider.notifier)
        .enterCode('P002'); // activeDay 2 in the mock

    final state = container.read(participantEntryProvider);
    expect(state.isReady, isTrue);
    expect(state.daySchedule!.dayNumber, 2);
    expect(state.daySchedule!.dayId, 'day2');
    expect(state.dayAlreadyCompleted, isFalse);
  });
}

/// Mock repo whose day-2 schedule document carries `dayNumber: 1` — the
/// corrupted-doc scenario that used to break the day-2 flow.
class _CorruptDayNumberRepository extends MockParticipantRepository {
  @override
  Future<DaySchedule> fetchSchedule(
    String participantCode,
    int dayNumber, {
    required PresentationStyle style,
  }) async {
    final base = await super.fetchSchedule(participantCode, dayNumber,
        style: style);
    // Day-2 doc incorrectly stored as day 1.
    return DaySchedule(
      dayNumber: 1,
      style: base.style,
      reminders: base.reminders,
    );
  }
}
