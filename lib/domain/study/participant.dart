import 'study_enums.dart';

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
      };

  factory Participant.fromJson(Map<String, Object?> json) => Participant(
        participantCode: json['participantCode'] as String? ?? 'UNKNOWN',
        serial: (json['serial'] as num?)?.toInt() ?? 0,
        styleOrder: StyleOrderWire.fromWireName(
            json['styleOrder'] as String? ?? 'AMBIENT_FIRST'),
        assignmentOverride: json['assignmentOverride'] as bool? ?? false,
        activeDay: (json['activeDay'] as num?)?.toInt() ?? 1,
        environment: json['environment'] as String? ?? 'dev',
        protocolVersion: json['protocolVersion'] as String? ?? 'unknown',
      );

  // ── CSV (admin export) ───────────────────────────────────────────

  static const csvHeader = <String>[
    'participantCode',
    'serial',
    'styleOrder',
    'assignmentOverride',
    'activeDay',
    'environment',
    'protocolVersion',
  ];

  List<Object?> toCsvRow() => [
        participantCode,
        serial,
        styleOrder.wireName,
        assignmentOverride,
        activeDay,
        environment,
        protocolVersion,
      ];
}
