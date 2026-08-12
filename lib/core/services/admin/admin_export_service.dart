import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../domain/study/csv_codec.dart';
import '../../../domain/study/participant.dart';
import '../../../domain/study/reminder_event.dart';
import '../../../domain/study/study_session.dart';
import 'admin_repository.dart';

/// In-app CSV export (plan §6.6): flattens a participant's Firestore subtree
/// into CSVs using the SAME serializers and headers as the on-device study
/// CSVs, so device files, admin exports, and script exports can never drift
/// into different column layouts.
class AdminExportService {
  AdminExportService(this._repository, {Directory? exportDir})
      : _exportDirOverride = exportDir;

  final AdminRepository _repository;
  final Directory? _exportDirOverride;

  static const _exportFolder = 'keti_exports';

  Future<Directory> exportDirectory() async {
    final root = _exportDirOverride ??
        Directory(p.join(
            (await getApplicationDocumentsDirectory()).path, _exportFolder));
    if (!root.existsSync()) root.createSync(recursive: true);
    return root;
  }

  /// Writes `P014_participant.csv`, `P014_sessions.csv`, `P014_events.csv`
  /// and returns them.
  Future<List<File>> exportParticipant(String participantCode) async {
    final dir = await exportDirectory();

    final participants = await _repository.listParticipants();
    final participant = participants.firstWhere(
      (p) => p.participantCode == participantCode,
      orElse: () => throw StateError('Unknown participant $participantCode'),
    );
    final sessions = await _repository.getSessions(participantCode);
    final events = <ReminderEvent>[];
    for (final dayId in const ['day1', 'day2']) {
      events.addAll(await _repository.getEvents(participantCode, dayId));
    }

    return [
      _writeCsv(
        p.join(dir.path, '${participantCode}_participant.csv'),
        Participant.csvHeader,
        [participant.toCsvRow()],
      ),
      _writeCsv(
        p.join(dir.path, '${participantCode}_sessions.csv'),
        StudySession.csvHeader,
        [
          for (final s in sessions)
            if (s != null) s.toCsvRow(),
        ],
      ),
      _writeCsv(
        p.join(dir.path, '${participantCode}_events.csv'),
        ReminderEvent.csvHeader,
        [for (final e in events) e.toCsvRow()],
      ),
    ];
  }

  /// Writes combined `all_participants.csv`, `all_sessions.csv`,
  /// `all_events.csv` across every participant.
  Future<List<File>> exportAll() async {
    final dir = await exportDirectory();
    final participants = await _repository.listParticipants();

    final sessionRows = <List<Object?>>[];
    final eventRows = <List<Object?>>[];
    for (final participant in participants) {
      final sessions = await _repository.getSessions(participant.participantCode);
      for (final s in sessions) {
        if (s != null) sessionRows.add(s.toCsvRow());
      }
      for (final dayId in const ['day1', 'day2']) {
        final events =
            await _repository.getEvents(participant.participantCode, dayId);
        for (final e in events) {
          eventRows.add(e.toCsvRow());
        }
      }
    }

    return [
      _writeCsv(
        p.join(dir.path, 'all_participants.csv'),
        Participant.csvHeader,
        [for (final participant in participants) participant.toCsvRow()],
      ),
      _writeCsv(p.join(dir.path, 'all_sessions.csv'), StudySession.csvHeader,
          sessionRows),
      _writeCsv(p.join(dir.path, 'all_events.csv'), ReminderEvent.csvHeader,
          eventRows),
    ];
  }

  /// Removes the exported CSVs for [participantCode] (full participant
  /// reset — stale exports must not outlive the reset).
  Future<void> deleteParticipantExports(String participantCode) async {
    final dir = await exportDirectory();
    for (final suffix in const [
      '_participant.csv',
      '_sessions.csv',
      '_events.csv',
    ]) {
      final file = File(p.join(dir.path, '$participantCode$suffix'));
      if (file.existsSync()) file.deleteSync();
    }
  }

  /// Opens the export folder in Finder (macOS only).
  Future<bool> revealExportDirectory() async {
    if (!Platform.isMacOS) return false;
    final dir = await exportDirectory();
    final result = await Process.run('open', [dir.path]);
    return result.exitCode == 0;
  }

  File _writeCsv(String path, List<String> header,
      Iterable<List<Object?>> rows) {
    final file = File(path);
    final tmp = File('$path.tmp');
    tmp.writeAsStringSync(CsvCodec.encode(header, rows), flush: true);
    if (file.existsSync()) file.deleteSync();
    tmp.renameSync(path);
    return file;
  }
}
