import 'study_enums.dart';

/// One row of a participant-day schedule (plan §5.1).
///
/// The schedule is identical in structure on both study days; only the
/// presentation style differs (resolved from the participant's style order).
class ScheduledReminder {
  const ScheduledReminder({
    required this.reminderNumber,
    required this.offset,
    required this.placement,
    required this.kind,
    required this.variantNumber,
  });

  /// 1-based position within the day (1–8).
  final int reminderNumber;

  /// Time after session start at which the reminder fires.
  final Duration offset;

  final Placement placement;
  final ReminderKind kind;

  /// Content variant counter: Hydration 1–5, Micro break 1–3.
  final int variantNumber;

  /// Stable variant identifier used in logs and exports,
  /// e.g. `hydration_1`, `micro_break_2`.
  String get contentVariantId =>
      '${kind == ReminderKind.hydration ? 'hydration' : 'micro_break'}_'
      '$variantNumber';

  Map<String, Object?> toJson() => {
        'n': reminderNumber,
        'offsetSec': offset.inSeconds,
        'placement': placement.wireName,
        'kind': kind.wireName,
        'variant': variantNumber,
      };

  factory ScheduledReminder.fromJson(Map<String, Object?> json) =>
      ScheduledReminder(
        reminderNumber: json['n'] as int,
        offset: Duration(seconds: json['offsetSec'] as int),
        placement: PlacementWire.fromWireName(json['placement'] as String),
        kind: ReminderKindWire.fromWireName(json['kind'] as String),
        variantNumber: json['variant'] as int,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledReminder &&
          reminderNumber == other.reminderNumber &&
          offset == other.offset &&
          placement == other.placement &&
          kind == other.kind &&
          variantNumber == other.variantNumber;

  @override
  int get hashCode =>
      Object.hash(reminderNumber, offset, placement, kind, variantNumber);
}

/// The default 8-reminder protocol schedule (plan §5.1).
///
/// Admin mode copies this template into each new participant's per-day
/// schedule documents; the style is resolved per day at session start.
/// Deterministic and auditable by design — times are offsets from session
/// start, never wall-clock.
const kDefaultScheduleTemplate = <ScheduledReminder>[
  ScheduledReminder(
    reminderNumber: 1,
    offset: Duration(minutes: 20),
    placement: Placement.cursorProximate,
    kind: ReminderKind.hydration,
    variantNumber: 1,
  ),
  ScheduledReminder(
    reminderNumber: 2,
    offset: Duration(minutes: 30),
    placement: Placement.notchCard,
    kind: ReminderKind.microBreak,
    variantNumber: 1,
  ),
  ScheduledReminder(
    reminderNumber: 3,
    offset: Duration(minutes: 40),
    placement: Placement.systemTray,
    kind: ReminderKind.hydration,
    variantNumber: 2,
  ),
  ScheduledReminder(
    reminderNumber: 4,
    offset: Duration(minutes: 60),
    placement: Placement.cursorProximate,
    kind: ReminderKind.microBreak,
    variantNumber: 2,
  ),
  ScheduledReminder(
    reminderNumber: 5,
    offset: Duration(minutes: 65),
    placement: Placement.notchCard,
    kind: ReminderKind.hydration,
    variantNumber: 3,
  ),
  ScheduledReminder(
    reminderNumber: 6,
    offset: Duration(minutes: 80),
    placement: Placement.cursorProximate,
    kind: ReminderKind.hydration,
    variantNumber: 4,
  ),
  ScheduledReminder(
    reminderNumber: 7,
    offset: Duration(minutes: 90),
    placement: Placement.systemTray,
    kind: ReminderKind.microBreak,
    variantNumber: 3,
  ),
  ScheduledReminder(
    reminderNumber: 8,
    offset: Duration(minutes: 100),
    placement: Placement.systemTray,
    kind: ReminderKind.hydration,
    variantNumber: 5,
  ),
];
