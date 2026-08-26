import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/study/csv_codec.dart';
import '../../../domain/study/event_log_entry.dart';
import '../../../domain/study/reminder_event.dart';
import '../../../domain/study/study_session.dart';

part 'csv_store.g.dart';

/// Default [CsvStore] instance. Lives here in the data layer so core services
/// (e.g. [SyncService]) can depend on it without reaching up into application.
@riverpod
CsvStore csvStore(Ref ref) => CsvStore();

/// Per-session on-device CSV store (plan §6.4).
///
/// Layout, rooted in the app's sandboxed documents directory:
/// ```
/// keti_data/{participantCode}/{dayId}/
///   session.csv     # one row: session snapshot for resume
///   events.csv      # 8 rows: latest state of every reminder event
///   event_log.csv   # append-only audit trail, never rewritten
/// ```
///
/// `events.csv` is rewritten atomically (temp file + rename) after every
/// mutation; `event_log.csv` is only ever appended to. The store is the
/// device-side ground truth for reconciliation with Firestore and the
/// emergency export source if the network never comes back.
class CsvStore {
  CsvStore({Directory? rootDir}) : _rootDirOverride = rootDir;

  /// Test seam: overrides the documents-directory root.
  final Directory? _rootDirOverride;

  static const _rootFolder = 'keti_data';
  static const _sessionFile = 'session.csv';
  static const _eventsFile = 'events.csv';
  static const _eventLogFile = 'event_log.csv';

  Future<Directory> _sessionDir(String code, String dayId) async {
    final root = _rootDirOverride ??
        Directory(p.join(
            (await getApplicationDocumentsDirectory()).path, _rootFolder));
    return Directory(p.join(root.path, code, dayId));
  }

  Future<bool> hasSession(String code, String dayId) async {
    final dir = await _sessionDir(code, dayId);
    return File(p.join(dir.path, _sessionFile)).existsSync();
  }

  /// Recursively deletes the entire day directory for [code] and [dayId].
  Future<void> deleteSessionDirectory(String code, String dayId) async {
    final dir = await _sessionDir(code, dayId);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  /// Recursively deletes ALL local data for [code] (`keti_data/{code}`) —
  /// full participant reset.
  Future<void> deleteParticipantDirectory(String code) async {
    final dir = await _sessionDir(code, 'day1');
    final parent = dir.parent;
    if (parent.existsSync()) {
      parent.deleteSync(recursive: true);
    }
  }

  // ── session.csv ──────────────────────────────────────────────────

  Future<void> writeSession(StudySession session) async {
    final dir = await _sessionDir(session.participantCode, session.dayId);
    dir.createSync(recursive: true);
    final text = CsvCodec.encode(StudySession.csvHeader, [session.toCsvRow()]);
    _writeAtomically(File(p.join(dir.path, _sessionFile)), text);
  }

  Future<StudySession?> readSession(String code, String dayId) async {
    final file =
        File(p.join((await _sessionDir(code, dayId)).path, _sessionFile));
    if (!file.existsSync()) return null;
    final rows = CsvCodec.decode(file.readAsStringSync());
    if (rows.length < 2) return null;
    return StudySession.fromCsvRow(rows[1]);
  }

  // ── events.csv (atomic rewrite of the full 8-row state) ──────────

  Future<void> writeEvents(
      String code, String dayId, List<ReminderEvent> events) async {
    final dir = await _sessionDir(code, dayId);
    dir.createSync(recursive: true);
    final text = CsvCodec.encode(
        ReminderEvent.csvHeader, events.map((e) => e.toCsvRow()));
    _writeAtomically(File(p.join(dir.path, _eventsFile)), text);
  }

  Future<List<ReminderEvent>?> readEvents(String code, String dayId) async {
    final file =
        File(p.join((await _sessionDir(code, dayId)).path, _eventsFile));
    if (!file.existsSync()) return null;
    final rows = CsvCodec.decode(file.readAsStringSync());
    if (rows.length < 2) return const [];
    return [for (var i = 1; i < rows.length; i++) ReminderEvent.fromCsvRow(rows[i])];
  }

  // ── event_log.csv (append-only) ──────────────────────────────────

  Future<void> appendEventLog(
      String code, String dayId, EventLogEntry entry) async {
    final dir = await _sessionDir(code, dayId);
    dir.createSync(recursive: true);
    final file = File(p.join(dir.path, _eventLogFile));
    final needsHeader = !file.existsSync() || file.lengthSync() == 0;
    final buffer = StringBuffer();
    if (needsHeader) {
      buffer.writeln(CsvCodec.encodeRow(EventLogEntry.csvHeader));
    }
    buffer.writeln(CsvCodec.encodeRow(entry.toCsvRow()));
    file.writeAsStringSync(buffer.toString(),
        mode: FileMode.append, flush: true);
  }

  Future<List<EventLogEntry>> readEventLog(String code, String dayId) async {
    final file =
        File(p.join((await _sessionDir(code, dayId)).path, _eventLogFile));
    if (!file.existsSync()) return const [];
    final rows = CsvCodec.decode(file.readAsStringSync());
    if (rows.length < 2) return const [];
    return [for (var i = 1; i < rows.length; i++) EventLogEntry.fromCsvRow(rows[i])];
  }

  // ── session discovery (resume) ───────────────────────────────────

  /// Returns the dayId of an unfinished (active) session for [code],
  /// checking day1 then day2. Null when nothing is resumable.
  Future<String?> findActiveDayId(String code) async {
    for (final dayId in const ['day1', 'day2']) {
      final session = await readSession(code, dayId);
      if (session != null && session.status == StudySessionStatus.active) {
        return dayId;
      }
    }
    return null;
  }

  // ── atomic write helper ──────────────────────────────────────────

  /// Writes [text] to [target] via a temp file + rename so a crash can
  /// never leave a half-written state file behind.
  ///
  /// Synchronous by design: the files are a handful of KB, and sync IO
  /// keeps the store usable inside `testWidgets`' fake-async zone (which
  /// starves real async IO futures).
  void _writeAtomically(File target, String text) {
    final tmp = File('${target.path}.tmp');
    tmp.writeAsStringSync(text, flush: true);
    if (target.existsSync()) {
      target.deleteSync();
    }
    tmp.renameSync(target.path);
  }
}
