import 'package:flutter_test/flutter_test.dart';
import 'package:keti/core/services/local/local_store.dart';
import 'package:keti/domain/study/day_schedule.dart';
import 'package:keti/domain/study/participant.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_config.dart';
import 'package:keti/domain/study/study_enums.dart';
import 'package:keti/domain/study/study_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LocalStore(await SharedPreferences.getInstance());
  });

  const participant = Participant(
    participantCode: 'P014',
    serial: 14,
    styleOrder: StyleOrder.characterFirst,
    assignmentOverride: false,
    activeDay: 1,
    environment: 'study',
    protocolVersion: '2026-08-v1',
  );

  const config = StudyConfig(
    protocolVersion: '2026-08-v1',
    defaultSchedule: kDefaultScheduleTemplate,
  );

  const schedule = DaySchedule(
    dayNumber: 1,
    style: PresentationStyle.characterBased,
    reminders: kDefaultScheduleTemplate,
  );

  const linkTemplates = StudyLinkTemplates(
    endOfDayType1: 'https://forms.example/ambient?pid={participantId}',
  );

  test('last participant code round-trips and defaults to null', () async {
    expect(store.lastParticipantCode, isNull);
    await store.setLastParticipantCode('P014');
    expect(store.lastParticipantCode, 'P014');
  });

  test('participant cache round-trips; missing key returns null', () async {
    expect(store.readCachedParticipant('P014'), isNull);
    await store.cacheParticipant(participant);
    final restored = store.readCachedParticipant('P014');
    expect(restored, isNotNull);
    expect(restored!.toJson(), participant.toJson());
  });

  test('study config cache round-trips', () async {
    expect(store.readCachedStudyConfig(), isNull);
    await store.cacheStudyConfig(config);
    final restored = store.readCachedStudyConfig();
    expect(restored!.protocolVersion, config.protocolVersion);
    expect(restored.defaultSchedule, kDefaultScheduleTemplate);
  });

  test('link templates cache round-trips', () async {
    expect(store.readCachedLinkTemplates().endOfDayType1, isNull);
    await store.cacheLinkTemplates(linkTemplates);
    final restored = store.readCachedLinkTemplates();
    expect(restored.endOfDayType1, linkTemplates.endOfDayType1);
    expect(restored.endOfDayType2, isNull);
  });

  test('schedule cache is keyed per participant and day', () async {
    expect(
      store.readCachedSchedule('P014', 'day1',
          style: PresentationStyle.characterBased),
      isNull,
    );
    await store.cacheScheduleFor('P014', schedule);
    final restored = store.readCachedSchedule('P014', 'day1',
        style: PresentationStyle.characterBased);
    expect(restored, isNotNull);
    expect(restored!.reminders, kDefaultScheduleTemplate);
    // A different day or participant misses.
    expect(
      store.readCachedSchedule('P014', 'day2',
          style: PresentationStyle.characterBased),
      isNull,
    );
    expect(
      store.readCachedSchedule('P099', 'day1',
          style: PresentationStyle.characterBased),
      isNull,
    );
  });

  test('active session pointer set, read, clear', () async {
    await store.setActiveSession('P014', 'day1');
    expect(store.readActiveSession('P014'), 'day1');
    await store.clearActiveSession('P014');
    expect(store.readActiveSession('P014'), isNull);
  });

  test('clearTutorialSeen removes the tutorial flag', () async {
    await store.setTutorialSeen('P014');
    expect(store.isTutorialSeen('P014'), isTrue);
    await store.clearTutorialSeen('P014');
    expect(store.isTutorialSeen('P014'), isFalse);
  });

  test('forgetCachedParticipant removes participant, schedules, session',
      () async {
    await store.cacheParticipant(participant);
    await store.cacheScheduleFor('P014', schedule);
    await store.cacheScheduleFor('P014',
        const DaySchedule(dayNumber: 2, style: PresentationStyle.ambient, reminders: kDefaultScheduleTemplate));
    await store.setActiveSession('P014', 'day1');

    await store.forgetCachedParticipant('P014');

    expect(store.readCachedParticipant('P014'), isNull);
    expect(store.readCachedSchedule('P014', 'day1', style: schedule.style),
        isNull);
    expect(store.readCachedSchedule('P014', 'day2', style: schedule.style),
        isNull);
    expect(store.readActiveSession('P014'), isNull);
  });

  test('reset watermark round-trips and defaults to null', () async {
    expect(store.readResetWatermark('P014'), isNull);
    await store.setResetWatermark('P014', '2026-08-12T12:00:00+02:00');
    expect(store.readResetWatermark('P014'), '2026-08-12T12:00:00+02:00');
  });

  test('values survive a fresh SharedPreferences instance', () async {
    await store.setLastParticipantCode('P014');
    await store.cacheParticipant(participant);
    final reopened = LocalStore(await SharedPreferences.getInstance());
    expect(reopened.lastParticipantCode, 'P014');
    expect(reopened.readCachedParticipant('P014')!.serial, 14);
  });
}
