/// One row of the append-only `event_log.csv` audit trail (plan §6.4).
///
/// Every state transition of every reminder event (and session-level events
/// like `session_started`, `app_resumed`) is appended here before the state
/// CSV is rewritten. The log is never rewritten, so a crash mid-write can
/// never lose earlier history.
class EventLogEntry {
  const EventLogEntry({
    required this.timestamp,
    required this.eventId,
    required this.transition,
    this.field,
    this.oldValue,
    this.newValue,
  });

  final DateTime timestamp;

  /// `reminder01`…`reminder08`, or `session` for session-level entries.
  final String eventId;

  /// e.g. `delivered`, `card_shown`, `answered`, `timed_out`, `suppressed`,
  /// `failed`, `session_started`, `session_resumed`, `app_paused`.
  final String transition;

  /// Optional changed field name (for field-level updates).
  final String? field;
  final String? oldValue;
  final String? newValue;

  static const csvHeader = <String>[
    'timestamp',
    'eventId',
    'transition',
    'field',
    'oldValue',
    'newValue',
  ];

  List<Object?> toCsvRow() => [
        timestamp.toIso8601String(),
        eventId,
        transition,
        field,
        oldValue,
        newValue,
      ];

  factory EventLogEntry.fromCsvRow(List<String> row) => EventLogEntry(
        timestamp: DateTime.parse(row[0]),
        eventId: row[1],
        transition: row[2],
        field: row[3].isEmpty ? null : row[3],
        oldValue: row[4].isEmpty ? null : row[4],
        newValue: row[5].isEmpty ? null : row[5],
      );
}
