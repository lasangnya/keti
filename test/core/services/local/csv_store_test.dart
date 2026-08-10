import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:keti/core/services/local/csv_store.dart';
import 'package:keti/domain/study/day_schedule.dart';
import 'package:keti/domain/study/event_log_entry.dart';
import 'package:keti/domain/study/reminder_event.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_config.dart';
import 'package:keti/domain/study/study_enums.dart';
import 'package:keti/domain/study/study_session.dart';

void main() {
  late Directory root;
  late CsvStore store;

  setUp(() {
    root = Directory.systemTemp.createTempSync('keti_csv_test');
    store = CsvStore(rootDir: root);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  StudySession buildSession({StudySessionStatus status = StudySessionStatus.active}) =>
      StudySession(
        participantCode: 'P014',
        dayNumber: 1,
        style: PresentationStyle.characterBased,
        status: status,
        startedAtLocal: DateTime.parse('2026-08-03T09:02:11+02:00'),
        schedule: const DaySchedule(
          dayNumber: 1,
          style: PresentationStyle.characterBased,
          reminders: kDefaultScheduleTemplate,
        ),
        links: const QuestionnaireLinks(),
      );

  List<ReminderEvent> buildEvents() => [
        for (final reminder in kDefaultScheduleTemplate)
          ReminderEvent.scheduled(
            participantCode: 'P014',
            dayNumber: 1,
            reminder: reminder,
            style: PresentationStyle.characterBased,
            sessionStartLocal: DateTime.parse('2026-08-03T09:02:11+02:00'),
            environment: 'study',
            appVersion: '1.0.0+2',
            protocolVersion: '2026-08-v1',
          ),
      ];

  group('session.csv', () {
    test('write + read round-trip; hasSession reflects existence', () async {
      expect(await store.hasSession('P014', 'day1'), isFalse);
      await store.writeSession(buildSession());
      expect(await store.hasSession('P014', 'day1'), isTrue);
      final restored = await store.readSession('P014', 'day1');
      expect(restored, isNotNull);
      expect(restored!.participantCode, 'P014');
      expect(restored.schedule.reminders, kDefaultScheduleTemplate);
    });

    test('readSession returns null when nothing was written', () async {
      expect(await store.readSession('P014', 'day2'), isNull);
    });
  });

  group('events.csv', () {
    test('writes and reads back 8 rows', () async {
      final events = buildEvents();
      await store.writeEvents('P014', 'day1', events);
      final restored = await store.readEvents('P014', 'day1');
      expect(restored, isNotNull);
      expect(restored!.length, 8);
      expect(restored[3].eventId, 'reminder04');
      expect(restored[3].toCsvRow().toString(), events[3].toCsvRow().toString());
    });

    test('rewrite replaces state atomically (no .tmp left behind)', () async {
      final events = buildEvents();
      await store.writeEvents('P014', 'day1', events);
      final updated = [...events];
      updated[0] = events[0].markDelivered(
        shownAtLocal: DateTime.parse('2026-08-03T09:22:12+02:00'),
        latenessMs: 900,
      );
      await store.writeEvents('P014', 'day1', updated);

      final restored = await store.readEvents('P014', 'day1');
      expect(restored![0].deliveryStatus, DeliveryStatus.delivered);
      expect(
        File('${root.path}/P014/day1/events.csv.tmp').existsSync(),
        isFalse,
      );
    });

    test('readEvents returns null when missing', () async {
      expect(await store.readEvents('P014', 'day2'), isNull);
    });
  });

  group('event_log.csv', () {
    test('appends entries with a header and never rewrites history', () async {
      await store.appendEventLog(
        'P014',
        'day1',
        EventLogEntry(
          timestamp: DateTime.parse('2026-08-03T09:02:11+02:00'),
          eventId: 'session',
          transition: 'session_started',
        ),
      );
      await store.appendEventLog(
        'P014',
        'day1',
        EventLogEntry(
          timestamp: DateTime.parse('2026-08-03T09:22:12+02:00'),
          eventId: 'reminder01',
          transition: 'delivered',
          field: 'deliveryStatus',
          oldValue: 'SCHEDULED',
          newValue: 'DELIVERED',
        ),
      );

      final log = await store.readEventLog('P014', 'day1');
      expect(log.length, 2);
      expect(log[0].transition, 'session_started');
      expect(log[1].newValue, 'DELIVERED');

      // Appending again preserves earlier rows.
      await store.appendEventLog(
        'P014',
        'day1',
        EventLogEntry(
          timestamp: DateTime.parse('2026-08-03T09:22:57+02:00'),
          eventId: 'reminder01',
          transition: 'hidden',
        ),
      );
      expect((await store.readEventLog('P014', 'day1')).length, 3);
    });

    test('log entry round-trips through the row codec', () {
      final entry = EventLogEntry(
        timestamp: DateTime.parse('2026-08-03T09:22:12+02:00'),
        eventId: 'reminder01',
        transition: 'answered',
        field: 'outcome',
        oldValue: 'NONE',
        newValue: 'COMPLETED',
      );
      final restored = EventLogEntry.fromCsvRow(
          entry.toCsvRow().map((v) => v?.toString() ?? '').toList());
      expect(restored.transition, 'answered');
      expect(restored.newValue, 'COMPLETED');
      expect(restored.timestamp, entry.timestamp);
    });
  });

  group('findActiveDayId', () {
    test('finds an unfinished session and skips completed ones', () async {
      expect(await store.findActiveDayId('P014'), isNull);

      await store.writeSession(buildSession());
      expect(await store.findActiveDayId('P014'), 'day1');

      await store.writeSession(
          buildSession().copyWith(status: StudySessionStatus.completed));
      expect(await store.findActiveDayId('P014'), isNull);
    });
  });
}
