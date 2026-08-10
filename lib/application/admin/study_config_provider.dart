import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/study/study_config.dart';
import 'admin_providers.dart';

part 'study_config_provider.g.dart';

@riverpod
class AdminStudyConfig extends _$AdminStudyConfig {
  @override
  Future<StudyConfig> build() =>
      ref.watch(adminRepositoryProvider).getConfig();

  Future<void> saveLinks(QuestionnaireLinks links) async {
    await ref.read(adminRepositoryProvider).saveQuestionnaireLinks(links);
    ref.invalidateSelf();
  }
}

/// Result of an export action, surfaced in the admin UI.
class AdminExportState {
  const AdminExportState({
    this.busy = false,
    this.lastMessage,
    this.lastFiles = const [],
  });

  final bool busy;
  final String? lastMessage;
  final List<String> lastFiles;
}

@Riverpod(keepAlive: true)
class AdminExport extends _$AdminExport {
  @override
  AdminExportState build() => const AdminExportState();

  Future<void> exportParticipant(String code) async {
    state = const AdminExportState(busy: true);
    try {
      final files =
          await ref.read(adminExportServiceProvider).exportParticipant(code);
      state = AdminExportState(
        lastMessage: 'Exported $code (${files.length} files)',
        lastFiles: [for (final f in files) f.path],
      );
    } catch (e) {
      state = AdminExportState(lastMessage: 'Export failed: $e');
    }
  }

  Future<void> exportAll() async {
    state = const AdminExportState(busy: true);
    try {
      final files = await ref.read(adminExportServiceProvider).exportAll();
      state = AdminExportState(
        lastMessage: 'Exported all participants (${files.length} files)',
        lastFiles: [for (final f in files) f.path],
      );
    } catch (e) {
      state = AdminExportState(lastMessage: 'Export failed: $e');
    }
  }

  Future<void> reveal() async {
    await ref.read(adminExportServiceProvider).revealExportDirectory();
  }
}
