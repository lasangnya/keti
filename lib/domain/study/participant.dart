import 'dart:convert';

import 'study_enums.dart';
import 'study_links.dart';

/// A pseudonymous study participant (plan §7.2 `participants/{code}`).
///
/// Created by the researcher in admin mode; the participant app only ever
/// reads this document. No real identity is stored anywhere in the system —
/// the code↔identity mapping lives in the researcher's consent records.
class Participant {
  const Participant({
    required this.participantCode,
    required this.serial,
    required this.styleOrder,
    required this.assignmentOverride,
    required this.activeDay,
    required this.environment,
    required this.protocolVersion,
    this.resetDay1At,
    this.resetDay2At,
    this.linkFlags = const ParticipantLinkFlags.allOn(),
  });

  /// Pseudonymous code, e.g. `P014`. Document key and the only identifier
  /// the participant ever types.
  final String participantCode;

  /// Numeric suffix of the code; its parity determines [styleOrder] by
  /// default (see `condition_assignment.dart`).
  final int serial;

  /// Counterbalancing order (admin-owned, client-immutable).
  final StyleOrder styleOrder;

  /// True when the researcher overrode the parity assignment at creation.
  final bool assignmentOverride;

  /// The day the participant is currently allowed to start (1 or 2).
  /// Flipped by the researcher ("Activate Day 2").
  final int activeDay;

  final String environment;
  final String protocolVersion;

  /// Server-signal to wipe local Day 1 data.
  final DateTime? resetDay1At;

  /// Server-signal to wipe local Day 2 data (same mechanism as
  /// [resetDay1At], for the day-2 schedule).
  final DateTime? resetDay2At;

  /// Per-participant switches deciding which questionnaires are offered
  /// (prestudy / end-of-day 1 / end-of-day 2 / final). Admin-written;
  /// defaults to all-on when absent.
  final ParticipantLinkFlags linkFlags;

  /// Accepts codes like `P001`…`P9999` (case-insensitive).
  static bool isValidCode(String code) =>
      RegExp(r'^[Pp]\d{3,4}$').hasMatch(code.trim());

  Map<String, Object?> toJson() => {
        'participantCode': participantCode,
        'serial': serial,
        'styleOrder': styleOrder.wireName,
        'assignmentOverride': assignmentOverride,
        'activeDay': activeDay,
        'environment': environment,
        'protocolVersion': protocolVersion,
        'resetDay1At': resetDay1At?.toIso8601String(),
        'resetDay2At': resetDay2At?.toIso8601String(),
        'linkFlags': linkFlags.toJson(),
      };

  factory Participant.fromJson(Map<String, Object?> json) {
    DateTime? parseDate(String key) {
      final val = json[key];
      if (val == null) return null;
      if (val is String) return val.isEmpty ? null : DateTime.parse(val);
      if (val is DateTime) return val;

      // Handle Firestore Timestamp (duck typing to avoid Firestore dependency in domain)
      try {
        return (val as dynamic).toDate() as DateTime;
      } catch (_) {
        return null;
      }
    }

    return Participant(
      participantCode: json['participantCode'] as String? ?? 'UNKNOWN',
      serial: (json['serial'] as num?)?.toInt() ?? 0,
      styleOrder: StyleOrderWire.fromWireName(
          json['styleOrder'] as String? ?? 'AMBIENT_FIRST'),
      assignmentOverride: json['assignmentOverride'] as bool? ?? false,
      activeDay: (json['activeDay'] as num?)?.toInt() ?? 1,
      environment: json['environment'] as String? ?? 'dev',
      protocolVersion: json['protocolVersion'] as String? ?? 'unknown',
      resetDay1At: parseDate('resetDay1At'),
      resetDay2At: parseDate('resetDay2At'),
      linkFlags: ParticipantLinkFlags.fromJson(
          (json['linkFlags'] as Map?)?.cast<String, Object?>()),
    );
  }

  // ── CSV (admin export) ───────────────────────────────────────────

  static const csvHeader = <String>[
    'participantCode',
    'serial',
    'styleOrder',
    'assignmentOverride',
    'activeDay',
    'environment',
    'protocolVersion',
    'linkFlags',
  ];

  List<Object?> toCsvRow() => [
        participantCode,
        serial,
        styleOrder.wireName,
        assignmentOverride,
        activeDay,
        environment,
        protocolVersion,
        jsonEncode(linkFlags.toJson()),
      ];
}
