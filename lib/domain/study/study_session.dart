import 'dart:convert';

import 'day_schedule.dart';
import 'study_config.dart';
import 'study_enums.dart';

/// Lifecycle of one participant-day session.
enum StudySessionStatus { active, completed, voided }

extension StudySessionStatusWire on StudySessionStatus {
  String get wireName => switch (this) {
        StudySessionStatus.active => 'ACTIVE',
        StudySessionStatus.completed => 'COMPLETED',
        StudySessionStatus.voided => 'VOIDED',
      };

  static StudySessionStatus fromWireName(String value) => switch (value) {
        'ACTIVE' => StudySessionStatus.active,
        'COMPLETED' => StudySessionStatus.completed,
        'VOIDED' => StudySessionStatus.voided,
        _ => throw ArgumentError.value(
            value, 'value', 'Unknown StudySessionStatus'),
      };
}

/// One participant-day session (plan §7.2 `studySessions/{dayId}`).
///
/// Holds the schedule and questionnaire-link snapshots taken at session
/// start so admin edits mid-session can never leak into a running session.
/// Serialized both to Firestore ([toJson]) and to the on-device
/// `session.csv` ([toCsvRow], with snapshots embedded as JSON strings).
class StudySession {
  const StudySession({
    required this.participantCode,
    required this.dayNumber,
    required this.style,
    required this.status,
    required this.startedAtLocal,
    required this.schedule,
    required this.links,
    this.completedAtLocal,
    this.resumedCount = 0,
  });

  final String participantCode;
  final int dayNumber;
  final PresentationStyle style;
  final StudySessionStatus status;
  final DateTime startedAtLocal;
  final DateTime? completedAtLocal;
  final int resumedCount;

  /// The 8 rows actually used for this session.
  final DaySchedule schedule;

  /// The link templates in effect at session start.
  final QuestionnaireLinks links;

  String get dayId => 'day$dayNumber';

  StudySession copyWith({
    StudySessionStatus? status,
    DateTime? completedAtLocal,
    int? resumedCount,
  }) =>
      StudySession(
        participantCode: participantCode,
        dayNumber: dayNumber,
        style: style,
        status: status ?? this.status,
        startedAtLocal: startedAtLocal,
        completedAtLocal: completedAtLocal ?? this.completedAtLocal,
        resumedCount: resumedCount ?? this.resumedCount,
        schedule: schedule,
        links: links,
      );

  // ── CSV (on-device session.csv) ──────────────────────────────────

  static const csvHeader = <String>[
    'participantCode',
    'dayId',
    'dayNumber',
    'style',
    'status',
    'startedAtLocal',
    'completedAtLocal',
    'resumedCount',
    'scheduleJson',
    'linksJson',
  ];

  List<Object?> toCsvRow() => [
        participantCode,
        dayId,
        dayNumber,
        style.wireName,
        status.wireName,
        startedAtLocal.toIso8601String(),
        completedAtLocal?.toIso8601String(),
        resumedCount,
        jsonEncode(schedule.toJson()),
        jsonEncode(links.toJson()),
      ];

  factory StudySession.fromCsvRow(List<String> row) {
    final style = PresentationStyleWire.fromWireName(row[3]);
    return StudySession(
      participantCode: row[0],
      dayNumber: int.parse(row[2]),
      style: style,
      status: StudySessionStatusWire.fromWireName(row[4]),
      startedAtLocal: DateTime.parse(row[5]),
      completedAtLocal: row[6].isEmpty ? null : DateTime.parse(row[6]),
      resumedCount: int.parse(row[7]),
      schedule: DaySchedule.fromJson(
          (jsonDecode(row[8]) as Map).cast<String, Object?>(),
          style: style),
      links: QuestionnaireLinks.fromJson(
          (jsonDecode(row[9]) as Map).cast<String, Object?>()),
    );
  }

  // ── JSON (Firestore document) ────────────────────────────────────

  Map<String, Object?> toJson() => {
        'dayId': dayId,
        'dayNumber': dayNumber,
        'participantCode': participantCode,
        'style': style.wireName,
        'status': status.wireName,
        'startedAtLocal': startedAtLocal.toIso8601String(),
        'completedAtLocal': completedAtLocal?.toIso8601String(),
        'resumedCount': resumedCount,
        'scheduleSnapshot': schedule.toJson()['reminders'],
        'linksSnapshot': links.toJson(),
      };

  factory StudySession.fromJson(Map<String, Object?> json) {
    final style = PresentationStyleWire.fromWireName(json['style'] as String);
    return StudySession(
      participantCode: json['participantCode'] as String,
      dayNumber: json['dayNumber'] as int,
      style: style,
      status: StudySessionStatusWire.fromWireName(json['status'] as String),
      startedAtLocal: DateTime.parse(json['startedAtLocal'] as String),
      completedAtLocal: json['completedAtLocal'] is String
          ? DateTime.parse(json['completedAtLocal'] as String)
          : null,
      resumedCount: (json['resumedCount'] as int?) ?? 0,
      schedule: DaySchedule.fromJson(
        {
          'dayNumber': json['dayNumber'],
          'reminders': json['scheduleSnapshot'],
        },
        style: style,
      ),
      links: QuestionnaireLinks.fromJson(
          (json['linksSnapshot'] as Map).cast<String, Object?>()),
    );
  }
}
