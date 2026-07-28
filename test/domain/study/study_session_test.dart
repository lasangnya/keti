import 'package:flutter_test/flutter_test.dart';
import 'package:keti/domain/study/csv_codec.dart';
import 'package:keti/domain/study/day_schedule.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_config.dart';
import 'package:keti/domain/study/study_enums.dart';
import 'package:keti/domain/study/study_session.dart';

StudySession buildSession() => StudySession(
      participantCode: 'P014',
      dayNumber: 1,
      style: PresentationStyle.characterBased,
      status: StudySessionStatus.active,
      startedAtLocal: DateTime.parse('2026-08-03T09:02:11+02:00'),
      resumedCount: 2,
      schedule: const DaySchedule(
        dayNumber: 1,
        style: PresentationStyle.characterBased,
        reminders: kDefaultScheduleTemplate,
      ),
      links: const QuestionnaireLinks(
        day1End: 'https://forms.example/end?pid={participantId}&day={day}',
      ),
    );

void main() {
  group('StudySessionStatus wire values', () {
    test('round-trip', () {
      for (final status in StudySessionStatus.values) {
        expect(StudySessionStatusWire.fromWireName(status.wireName), status);
      }
      expect(StudySessionStatus.active.wireName, 'ACTIVE');
      expect(StudySessionStatus.voided.wireName, 'VOIDED');
    });
  });

  group('StudySession CSV', () {
    test('row round-trips through the codec, snapshots intact', () {
      final session = buildSession();
      final text = CsvCodec.encode(StudySession.csvHeader, [session.toCsvRow()]);
      final rows = CsvCodec.decode(text);
      expect(rows.length, 2);
      final restored = StudySession.fromCsvRow(rows[1]);
      expect(restored.participantCode, 'P014');
      expect(restored.dayId, 'day1');
      expect(restored.style, PresentationStyle.characterBased);
      expect(restored.status, StudySessionStatus.active);
      expect(restored.resumedCount, 2);
      expect(restored.schedule.reminders, kDefaultScheduleTemplate);
      expect(restored.links.day1End, session.links.day1End);
    });

    test('completed session round-trips with completedAtLocal', () {
      final session = buildSession().copyWith(
        status: StudySessionStatus.completed,
        completedAtLocal: DateTime.parse('2026-08-03T11:05:00+02:00'),
      );
      final text = CsvCodec.encode(StudySession.csvHeader, [session.toCsvRow()]);
      final restored = StudySession.fromCsvRow(CsvCodec.decode(text)[1]);
      expect(restored.status, StudySessionStatus.completed);
      expect(restored.completedAtLocal,
          DateTime.parse('2026-08-03T11:05:00+02:00'));
    });
  });

  group('StudySession JSON', () {
    test('round-trips', () {
      final session = buildSession();
      final restored = StudySession.fromJson(session.toJson());
      expect(restored.toJson(), session.toJson());
    });

    test('embeds schedule and link snapshots', () {
      final json = buildSession().toJson();
      expect(json['scheduleSnapshot'], isA<List>());
      expect((json['scheduleSnapshot'] as List).length, 8);
      expect(json['linksSnapshot'], isA<Map>());
      expect(json['status'], 'ACTIVE');
      expect(json['style'], 'CHARACTER_BASED');
    });
  });
}
