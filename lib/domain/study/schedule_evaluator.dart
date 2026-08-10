import '../../core/constants/app_config.dart';
import 'scheduled_reminder.dart';

/// The outcome of evaluating one reminder against the current time.
sealed class ScheduleDecision {
  const ScheduleDecision(this.reminder);

  final ScheduledReminder reminder;
}

/// The reminder is due now (on time or within the grace window).
class ScheduleDue extends ScheduleDecision {
  const ScheduleDue(super.reminder, this.latenessMs);

  /// How late after the absolute fire time this delivery is (0 when on time).
  final int latenessMs;
}

/// The reminder's fire time passed beyond the grace window — it must be
/// recorded, not shown.
class ScheduleMissed extends ScheduleDecision {
  const ScheduleMissed(super.reminder, this.reason);

  /// e.g. `late_delivery`, `device_inactive`, `app_terminated`.
  final String reason;
}

/// Pure scheduling core (plan §5.2).
///
/// Timing is absolute: fire times are `sessionStartLocal + offset`, compared
/// against [now] — never accumulated durations, so the result is immune to
/// timer throttling, App Nap, and clock drift.
///
/// Returns one decision per reminder that is due or missed right now.
/// Reminders whose fire time is in the future, or whose number is in
/// [finalizedReminders], are skipped.
List<ScheduleDecision> evaluateSchedule({
  required DateTime now,
  required DateTime sessionStartLocal,
  required List<ScheduledReminder> schedule,
  required Set<int> finalizedReminders,
  int graceMs = AppConfig.lateDeliveryGraceMs,
  String missedReason = 'late_delivery',
}) {
  final decisions = <ScheduleDecision>[];
  for (final reminder in schedule) {
    if (finalizedReminders.contains(reminder.reminderNumber)) continue;
    final fireTime = sessionStartLocal.add(reminder.offset);
    final latenessMs = now.difference(fireTime).inMilliseconds;
    if (latenessMs < 0) continue; // not yet due
    if (latenessMs <= graceMs) {
      decisions.add(ScheduleDue(reminder, latenessMs));
    } else {
      decisions.add(ScheduleMissed(reminder, missedReason));
    }
  }
  return decisions;
}

/// True when every reminder in the schedule has a final state.
bool scheduleComplete({
  required List<ScheduledReminder> schedule,
  required Set<int> finalizedReminders,
}) =>
    schedule.every((r) => finalizedReminders.contains(r.reminderNumber));
