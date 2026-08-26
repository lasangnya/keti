import 'package:flutter_test/flutter_test.dart';
import 'package:keti/application/study/scheduler_provider.dart';
import 'package:keti/domain/study/schedule_evaluator.dart';
import 'package:keti/domain/study/scheduled_reminder.dart';
import 'package:keti/domain/study/study_enums.dart';

void main() {
  final start = DateTime.parse('2026-08-03T09:00:00+02:00');

  ScheduledReminder reminder(int number, int minutes) => ScheduledReminder(
        reminderNumber: number,
        offset: Duration(minutes: minutes),
        placement: Placement.cursorProximate,
        kind: ReminderKind.hydration,
        variantNumber: 1,
      );

  StudyScheduler makeScheduler(
    DateTime Function() clock,
    Future<void> Function(List<ScheduleDecision>) onDecisions,
  ) =>
      StudyScheduler(clock: clock, onDecisions: onDecisions);

  test('delivers an on-time reminder as due with zero lateness', () async {
    var now = start;
    final decisions = <ScheduleDecision>[];
    final scheduler = makeScheduler(() => now, (d) async => decisions.addAll(d));
    scheduler.start(
      sessionStartLocal: start,
      schedule: [reminder(1, 20)],
      finalizedReminders: {},
      tickInterval: const Duration(hours: 1),
    );
    addTearDown(scheduler.stop);

    await scheduler.tickOnce();
    expect(decisions, isEmpty);

    now = start.add(const Duration(minutes: 20));
    await scheduler.tickOnce();

    expect(decisions, hasLength(1));
    final due = decisions.single as ScheduleDue;
    expect(due.reminder.reminderNumber, 1);
    expect(due.latenessMs, 0);
  });

  test('a long gap marks missed reminders device_inactive', () async {
    var now = start;
    final decisions = <ScheduleDecision>[];
    final scheduler = makeScheduler(() => now, (d) async => decisions.addAll(d));
    scheduler.start(
      sessionStartLocal: start,
      schedule: [reminder(1, 20)],
      finalizedReminders: {},
      tickInterval: const Duration(hours: 1),
    );
    addTearDown(scheduler.stop);

    await scheduler.tickOnce();
    // 25 minutes later: reminder 1 (20 min) is 5 min past grace, and the
    // 25-min tick gap exceeds the stall threshold.
    now = start.add(const Duration(minutes: 25));
    await scheduler.tickOnce();

    expect(decisions, hasLength(1));
    final missed = decisions.single as ScheduleMissed;
    expect(missed.reminder.reminderNumber, 1);
    expect(missed.reason, 'device_inactive');
  });

  test('finish stops further ticks', () async {
    var now = start;
    final decisions = <ScheduleDecision>[];
    final scheduler = makeScheduler(() => now, (d) async => decisions.addAll(d));
    scheduler.start(
      sessionStartLocal: start,
      schedule: [reminder(1, 20)],
      finalizedReminders: {},
      tickInterval: const Duration(hours: 1),
    );
    addTearDown(scheduler.stop);

    scheduler.finish();
    now = start.add(const Duration(minutes: 25));
    await scheduler.tickOnce();

    expect(decisions, isEmpty);
  });

  test('delivered reminders are finalized and not re-evaluated', () async {
    var now = start;
    final decisions = <ScheduleDecision>[];
    final scheduler = makeScheduler(() => now, (d) async => decisions.addAll(d));
    scheduler.start(
      sessionStartLocal: start,
      schedule: [reminder(1, 20)],
      finalizedReminders: {},
      tickInterval: const Duration(hours: 1),
    );
    addTearDown(scheduler.stop);

    await scheduler.tickOnce();
    now = start.add(const Duration(minutes: 20));
    await scheduler.tickOnce();
    expect(decisions, hasLength(1));

    now = start.add(const Duration(minutes: 25));
    await scheduler.tickOnce();
    expect(decisions, hasLength(1));
  });

  test('onDecisions is not invoked when nothing is due', () async {
    var now = start;
    var calls = 0;
    final scheduler = makeScheduler(() => now, (_) async => calls++);
    scheduler.start(
      sessionStartLocal: start,
      schedule: [reminder(1, 20)],
      finalizedReminders: {},
      tickInterval: const Duration(hours: 1),
    );
    addTearDown(scheduler.stop);

    await scheduler.tickOnce();
    now = start.add(const Duration(minutes: 10));
    await scheduler.tickOnce();

    expect(calls, 0);
  });

  test('isRunning reflects start and stop', () {
    final scheduler = makeScheduler(() => start, (_) async {});
    expect(scheduler.isRunning, isFalse);

    scheduler.start(
      sessionStartLocal: start,
      schedule: [reminder(1, 20)],
      finalizedReminders: {},
      tickInterval: const Duration(hours: 1),
    );
    expect(scheduler.isRunning, isTrue);

    scheduler.stop();
    expect(scheduler.isRunning, isFalse);
  });
}
