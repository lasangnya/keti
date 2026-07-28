import 'scheduled_reminder.dart';
import 'study_enums.dart';

/// One record per reminder exposure (plan §5.1 / §7.2).
///
/// The same field layout is used for the Firestore `reminderEvents` document,
/// the on-device `events.csv` row, and the admin CSV export — [toJson],
/// [toCsvRow] and [csvHeader] are the single source of truth so the three
/// can never drift apart.
///
/// Server-authoritative timestamps (`reminderShownAt`, `answeredAt`,
/// `updatedAt` as Firestore `serverTimestamp()`) are added by the repository
/// layer at write time and are intentionally not part of this model; the
/// local ISO-8601 fields here are the device's record.
class ReminderEvent {
  const ReminderEvent({
    required this.eventId,
    required this.participantCode,
    required this.dayId,
    required this.dayNumber,
    required this.reminderNumber,
    required this.scheduledOffsetSec,
    required this.scheduledAtLocal,
    required this.placement,
    required this.style,
    required this.reminderKind,
    required this.contentVariantId,
    required this.deliveryStatus,
    required this.outcome,
    required this.usedFallback,
    required this.sessionResumed,
    required this.environment,
    required this.appVersion,
    required this.protocolVersion,
    this.reminderShownAtLocal,
    this.reminderHiddenAtLocal,
    this.deliveryLatenessMs,
    this.failureReason,
    this.suppressionReason,
    this.cardShownAtLocal,
    this.answeredAtLocal,
    this.responseLatencyMs,
  });

  // ── Identity & schedule (write-once) ─────────────────────────────
  final String eventId; // "reminder01"…"reminder08"
  final String participantCode; // e.g. "P014"
  final String dayId; // "day1" | "day2"
  final int dayNumber; // 1 | 2
  final int reminderNumber; // 1–8
  final int scheduledOffsetSec;
  final DateTime scheduledAtLocal;

  // ── Reminder display lifecycle ───────────────────────────────────
  final DateTime? reminderShownAtLocal;
  final DateTime? reminderHiddenAtLocal;
  final int? deliveryLatenessMs;

  // ── Condition (write-once) ───────────────────────────────────────
  final Placement placement;
  final PresentationStyle style;
  final ReminderKind reminderKind;
  final String contentVariantId;

  // ── Technical outcome ────────────────────────────────────────────
  final DeliveryStatus deliveryStatus;
  final String? failureReason;
  final String? suppressionReason;
  final bool usedFallback;

  // ── Behavioral outcome (uniform compliance card) ─────────────────
  final DateTime? cardShownAtLocal;
  final ResponseOutcome outcome;
  final DateTime? answeredAtLocal;
  final int? responseLatencyMs;

  // ── Audit ────────────────────────────────────────────────────────
  final bool sessionResumed;
  final String environment;
  final String appVersion;
  final String protocolVersion;

  /// Creates the pre-scheduled record written at session start
  /// ([DeliveryStatus.scheduled], [ResponseOutcome.none]).
  factory ReminderEvent.scheduled({
    required String participantCode,
    required int dayNumber,
    required ScheduledReminder reminder,
    required PresentationStyle style,
    required DateTime sessionStartLocal,
    required String environment,
    required String appVersion,
    required String protocolVersion,
    bool sessionResumed = false,
  }) {
    final n = reminder.reminderNumber;
    return ReminderEvent(
      eventId: 'reminder${n.toString().padLeft(2, '0')}',
      participantCode: participantCode,
      dayId: 'day$dayNumber',
      dayNumber: dayNumber,
      reminderNumber: n,
      scheduledOffsetSec: reminder.offset.inSeconds,
      scheduledAtLocal: sessionStartLocal.add(reminder.offset),
      placement: reminder.placement,
      style: style,
      reminderKind: reminder.kind,
      contentVariantId: reminder.contentVariantId,
      deliveryStatus: DeliveryStatus.scheduled,
      outcome: ResponseOutcome.none,
      usedFallback: false,
      sessionResumed: sessionResumed,
      environment: environment,
      appVersion: appVersion,
      protocolVersion: protocolVersion,
    );
  }

  // ── Lifecycle transitions (each returns a new immutable instance) ─

  ReminderEvent markDelivered({
    required DateTime shownAtLocal,
    required int latenessMs,
    bool usedFallback = false,
  }) =>
      _copy(
        deliveryStatus: DeliveryStatus.delivered,
        reminderShownAtLocal: shownAtLocal,
        deliveryLatenessMs: latenessMs,
        usedFallback: usedFallback,
      );

  ReminderEvent markReminderHidden(DateTime hiddenAtLocal) =>
      _copy(reminderHiddenAtLocal: hiddenAtLocal);

  ReminderEvent markCardShown(DateTime shownAtLocal) =>
      _copy(cardShownAtLocal: shownAtLocal);

  /// Records a button outcome ([ResponseOutcome.completed] or
  /// [ResponseOutcome.dismissed]) and computes response latency from
  /// [cardShownAtLocal] when available.
  ReminderEvent markAnswered({
    required ResponseOutcome outcome,
    required DateTime answeredAtLocal,
  }) {
    final cardShown = cardShownAtLocal;
    return _copy(
      outcome: outcome,
      answeredAtLocal: answeredAtLocal,
      responseLatencyMs: cardShown == null
          ? null
          : answeredAtLocal.difference(cardShown).inMilliseconds,
    );
  }

  ReminderEvent markTimedOut(DateTime atLocal) => _copy(
        outcome: ResponseOutcome.timedOut,
        answeredAtLocal: atLocal,
      );

  ReminderEvent markSuppressed(String reason) => _copy(
        deliveryStatus: DeliveryStatus.suppressed,
        suppressionReason: reason,
      );

  ReminderEvent markFailed(String reason) => _copy(
        deliveryStatus: DeliveryStatus.failed,
        failureReason: reason,
      );

  ReminderEvent markNotDisplayed(String reason) => _copy(
        deliveryStatus: DeliveryStatus.notDisplayed,
        suppressionReason: reason,
      );

  ReminderEvent markSessionResumed() => _copy(sessionResumed: true);

  ReminderEvent _copy({
    DateTime? reminderShownAtLocal,
    DateTime? reminderHiddenAtLocal,
    int? deliveryLatenessMs,
    DeliveryStatus? deliveryStatus,
    String? failureReason,
    String? suppressionReason,
    bool? usedFallback,
    DateTime? cardShownAtLocal,
    ResponseOutcome? outcome,
    DateTime? answeredAtLocal,
    int? responseLatencyMs,
    bool? sessionResumed,
  }) =>
      ReminderEvent(
        eventId: eventId,
        participantCode: participantCode,
        dayId: dayId,
        dayNumber: dayNumber,
        reminderNumber: reminderNumber,
        scheduledOffsetSec: scheduledOffsetSec,
        scheduledAtLocal: scheduledAtLocal,
        placement: placement,
        style: style,
        reminderKind: reminderKind,
        contentVariantId: contentVariantId,
        environment: environment,
        appVersion: appVersion,
        protocolVersion: protocolVersion,
        reminderShownAtLocal: reminderShownAtLocal ?? this.reminderShownAtLocal,
        reminderHiddenAtLocal:
            reminderHiddenAtLocal ?? this.reminderHiddenAtLocal,
        deliveryLatenessMs: deliveryLatenessMs ?? this.deliveryLatenessMs,
        deliveryStatus: deliveryStatus ?? this.deliveryStatus,
        failureReason: failureReason ?? this.failureReason,
        suppressionReason: suppressionReason ?? this.suppressionReason,
        usedFallback: usedFallback ?? this.usedFallback,
        cardShownAtLocal: cardShownAtLocal ?? this.cardShownAtLocal,
        outcome: outcome ?? this.outcome,
        answeredAtLocal: answeredAtLocal ?? this.answeredAtLocal,
        responseLatencyMs: responseLatencyMs ?? this.responseLatencyMs,
        sessionResumed: sessionResumed ?? this.sessionResumed,
      );

  // ── CSV (on-device events.csv + admin export) ────────────────────

  /// Frozen column order (protocol versioned). Any change here requires a
  /// protocol-version bump.
  static const csvHeader = <String>[
    'eventId',
    'participantCode',
    'dayId',
    'dayNumber',
    'reminderNumber',
    'scheduledOffsetSec',
    'scheduledAtLocal',
    'reminderShownAtLocal',
    'reminderHiddenAtLocal',
    'deliveryLatenessMs',
    'placement',
    'style',
    'reminderKind',
    'contentVariantId',
    'deliveryStatus',
    'failureReason',
    'suppressionReason',
    'usedFallback',
    'cardShownAtLocal',
    'outcome',
    'answeredAtLocal',
    'responseLatencyMs',
    'sessionResumed',
    'environment',
    'appVersion',
    'protocolVersion',
  ];

  List<Object?> toCsvRow() => [
        eventId,
        participantCode,
        dayId,
        dayNumber,
        reminderNumber,
        scheduledOffsetSec,
        scheduledAtLocal.toIso8601String(),
        reminderShownAtLocal?.toIso8601String(),
        reminderHiddenAtLocal?.toIso8601String(),
        deliveryLatenessMs,
        placement.wireName,
        style.wireName,
        reminderKind.wireName,
        contentVariantId,
        deliveryStatus.wireName,
        failureReason,
        suppressionReason,
        usedFallback,
        cardShownAtLocal?.toIso8601String(),
        outcome.wireName,
        answeredAtLocal?.toIso8601String(),
        responseLatencyMs,
        sessionResumed,
        environment,
        appVersion,
        protocolVersion,
      ];

  /// Positional decode of one CSV row in [csvHeader] order. Empty strings
  /// decode as `null` for nullable fields.
  factory ReminderEvent.fromCsvRow(List<String> row) {
    String at(int i) => row[i];
    String? nullable(int i) => row[i].isEmpty ? null : row[i];
    DateTime? dateAt(int i) =>
        row[i].isEmpty ? null : DateTime.parse(row[i]);
    int? intAt(int i) => row[i].isEmpty ? null : int.parse(row[i]);

    return ReminderEvent(
      eventId: at(0),
      participantCode: at(1),
      dayId: at(2),
      dayNumber: int.parse(at(3)),
      reminderNumber: int.parse(at(4)),
      scheduledOffsetSec: int.parse(at(5)),
      scheduledAtLocal: DateTime.parse(at(6)),
      reminderShownAtLocal: dateAt(7),
      reminderHiddenAtLocal: dateAt(8),
      deliveryLatenessMs: intAt(9),
      placement: PlacementWire.fromWireName(at(10)),
      style: PresentationStyleWire.fromWireName(at(11)),
      reminderKind: ReminderKindWire.fromWireName(at(12)),
      contentVariantId: at(13),
      deliveryStatus: DeliveryStatusWire.fromWireName(at(14)),
      failureReason: nullable(15),
      suppressionReason: nullable(16),
      usedFallback: at(17) == 'true',
      cardShownAtLocal: dateAt(18),
      outcome: ResponseOutcomeWire.fromWireName(at(19)),
      answeredAtLocal: dateAt(20),
      responseLatencyMs: intAt(21),
      sessionResumed: at(22) == 'true',
      environment: at(23),
      appVersion: at(24),
      protocolVersion: at(25),
    );
  }

  // ── JSON (Firestore document; server timestamps added by the repo) ─

  Map<String, Object?> toJson() => {
        'eventId': eventId,
        'participantCode': participantCode,
        'dayId': dayId,
        'dayNumber': dayNumber,
        'reminderNumber': reminderNumber,
        'scheduledOffsetSec': scheduledOffsetSec,
        'scheduledAtLocal': scheduledAtLocal.toIso8601String(),
        'reminderShownAtLocal': reminderShownAtLocal?.toIso8601String(),
        'reminderHiddenAtLocal': reminderHiddenAtLocal?.toIso8601String(),
        'deliveryLatenessMs': deliveryLatenessMs,
        'placement': placement.wireName,
        'style': style.wireName,
        'reminderKind': reminderKind.wireName,
        'contentVariantId': contentVariantId,
        'deliveryStatus': deliveryStatus.wireName,
        'failureReason': failureReason,
        'suppressionReason': suppressionReason,
        'usedFallback': usedFallback,
        'cardShownAtLocal': cardShownAtLocal?.toIso8601String(),
        'outcome': outcome.wireName,
        'answeredAtLocal': answeredAtLocal?.toIso8601String(),
        'responseLatencyMs': responseLatencyMs,
        'sessionResumed': sessionResumed,
        'environment': environment,
        'appVersion': appVersion,
        'protocolVersion': protocolVersion,
      };

  factory ReminderEvent.fromJson(Map<String, Object?> json) {
    DateTime? date(String key) {
      final value = json[key];
      return value is String && value.isNotEmpty ? DateTime.parse(value) : null;
    }

    int? nullableInt(String key) => json[key] as int?;

    return ReminderEvent(
      eventId: json['eventId'] as String,
      participantCode: json['participantCode'] as String,
      dayId: json['dayId'] as String,
      dayNumber: json['dayNumber'] as int,
      reminderNumber: json['reminderNumber'] as int,
      scheduledOffsetSec: json['scheduledOffsetSec'] as int,
      scheduledAtLocal: DateTime.parse(json['scheduledAtLocal'] as String),
      reminderShownAtLocal: date('reminderShownAtLocal'),
      reminderHiddenAtLocal: date('reminderHiddenAtLocal'),
      deliveryLatenessMs: nullableInt('deliveryLatenessMs'),
      placement: PlacementWire.fromWireName(json['placement'] as String),
      style: PresentationStyleWire.fromWireName(json['style'] as String),
      reminderKind:
          ReminderKindWire.fromWireName(json['reminderKind'] as String),
      contentVariantId: json['contentVariantId'] as String,
      deliveryStatus:
          DeliveryStatusWire.fromWireName(json['deliveryStatus'] as String),
      failureReason: json['failureReason'] as String?,
      suppressionReason: json['suppressionReason'] as String?,
      usedFallback: json['usedFallback'] as bool,
      cardShownAtLocal: date('cardShownAtLocal'),
      outcome: ResponseOutcomeWire.fromWireName(json['outcome'] as String),
      answeredAtLocal: date('answeredAtLocal'),
      responseLatencyMs: nullableInt('responseLatencyMs'),
      sessionResumed: json['sessionResumed'] as bool,
      environment: json['environment'] as String,
      appVersion: json['appVersion'] as String,
      protocolVersion: json['protocolVersion'] as String,
    );
  }
}
