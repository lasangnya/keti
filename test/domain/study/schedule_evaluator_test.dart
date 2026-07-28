import 'package:flutter_test/flutter_test.dart';
import 'package:keti/domain/study/schedule_evaluator.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';

void main() {
  final start = DateTime.parse('2026-08-03T09:00:00+02:00');

  Set<int> none = {};

  group('evaluateSchedule', () {
    test('nothing is due before the first fire time', () {
      final decisions = evaluateSchedule(
        now: start.add(const Duration(minutes: 19, seconds: 59)),
        sessionStartLocal: start,
        schedule: kDefaultScheduleTemplate,
        finalizedReminders: none,
      );
      expect(decisions, isEmpty);
    });

    test('exactly on the fire time is due with zero lateness', () {
      final decisions = evaluateSchedule(
        now: start.add(const Duration(minutes: 20)),
        sessionStartLocal: start,
        schedule: kDefaultScheduleTemplate,
        finalizedReminders: none,
      );
      expect(decisions, hasLength(1));
      final due = decisions.single as ScheduleDue;
      expect(due.reminder.reminderNumber, 1);
      expect(due.latenessMs, 0);
    });

    test('within the grace window is due with measured lateness', () {
      final decisions = evaluateSchedule(
        now: start.add(const Duration(minutes: 21, seconds: 30)),
        sessionStartLocal: start,
        schedule: kDefaultScheduleTemplate,
        finalizedReminders: none,
      );
      final due = decisions.single as ScheduleDue;
      expect(due.latenessMs, 90000);
    });

    test('past the grace window is missed, not due', () {
      final decisions = evaluateSchedule(
        now: start.add(const Duration(minutes: 22, seconds: 1)),
        sessionStartLocal: start,
        schedule: kDefaultScheduleTemplate,
        finalizedReminders: none,
      );
      final missed = decisions.single as ScheduleMissed;
      expect(missed.reminder.reminderNumber, 1);
      expect(missed.reason, 'late_delivery');
    });

    test('finalized reminders are never evaluated again', () {
      final decisions = evaluateSchedule(
        now: start.add(const Duration(minutes: 20)),
        sessionStartLocal: start,
        schedule: kDefaultScheduleTemplate,
        finalizedReminders: {1},
      );
      expect(decisions, isEmpty);
    });

    test('several reminders surface at once after a long gap', () {
      // App slept from 00:00 to 00:41 — reminders 1 (00:20) and 2 (00:30)
      // are past grace (missed); reminder 3 (00:40) is 60 s late → still due.
      final decisions = evaluateSchedule(
        now: start.add(const Duration(minutes: 41)),
        sessionStartLocal: start,
        schedule: kDefaultScheduleTemplate,
        finalizedReminders: none,
        missedReason: 'device_inactive',
      );
      expect(decisions, hasLength(3));
      expect(decisions.map((d) => d.reminder.reminderNumber), [1, 2, 3]);
      expect(decisions[0], isA<ScheduleMissed>());
      expect(decisions[1], isA<ScheduleMissed>());
      expect((decisions[0] as ScheduleMissed).reason, 'device_inactive');
      expect(decisions[2], isA<ScheduleDue>());
      expect((decisions[2] as ScheduleDue).latenessMs, 60000);
    });

    test('custom grace window is honoured', () {
      final decisions = evaluateSchedule(
        now: start.add(const Duration(minutes: 20, seconds: 30)),
        sessionStartLocal: start,
        schedule: kDefaultScheduleTemplate,
        finalizedReminders: none,
        graceMs: 10000,
      );
      expect(decisions.single, isA<ScheduleMissed>());
    });
  });

  group('scheduleComplete', () {
    test('only true when all 8 are finalized', () {
      expect(
        scheduleComplete(
          schedule: kDefaultScheduleTemplate,
          finalizedReminders: {1, 2, 3, 4, 5, 6, 7},
        ),
        isFalse,
      );
      expect(
        scheduleComplete(
          schedule: kDefaultScheduleTemplate,
          finalizedReminders: {1, 2, 3, 4, 5, 6, 7, 8},
        ),
        isTrue,
      );
    });
  });
}
