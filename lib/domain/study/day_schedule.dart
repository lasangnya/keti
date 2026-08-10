import 'scheduled_reminder.dart';
import 'study_enums.dart';

/// A participant's schedule for one study day (plan §5.1).
///
/// Fetched from `participants/{code}/schedules/{dayId}` on ID entry and
/// snapshotted into the session document at session start, so admin edits
/// made mid-session can never leak into a running session.
///
/// The Firestore document does not store [style] — it is derived from the
/// participant's style order and the day number — so it is supplied by the
/// caller on [DaySchedule.fromJson].
class DaySchedule {
  const DaySchedule({
    required this.dayNumber,
    required this.style,
    required this.reminders,
  });

  /// 1 or 2.
  final int dayNumber;

  /// The presentation style in effect for the whole day.
  final PresentationStyle style;

  /// Reminders ordered by [ScheduledReminder.reminderNumber]. The admin can
  /// configure any count; the default template has 8.
  final List<ScheduledReminder> reminders;

  String get dayId => 'day$dayNumber';

  Map<String, Object?> toJson() => {
        'dayId': dayId,
        'dayNumber': dayNumber,
        'reminders': reminders.map((r) => r.toJson()).toList(),
      };

  factory DaySchedule.fromJson(
    Map<String, Object?> json, {
    required PresentationStyle style,
  }) {
    final rawReminders = (json['reminders'] as List? ?? [])
        .map((r) =>
            ScheduledReminder.fromJson((r as Map).cast<String, Object?>()))
        .toList();
    return DaySchedule(
      dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 1,
      style: style,
      reminders: rawReminders,
    );
  }
}
