import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/services/cursor_pill_service.dart';
import '../../core/services/notch_hook_service.dart';
import '../../core/services/tray_pill_service.dart';
import '../../domain/reminders/reminder_content.dart';

part 'reminder_manager.g.dart';

@riverpod
class ReminderManager extends _$ReminderManager {
  final List<ReminderRequest> _queue = [];
  bool _isProcessing = false;

  @override
  void build() {
    // Keep alive permanently — the queue must survive across page navigations
    // and not be auto-disposed while a reminder is still showing natively.
    ref.keepAlive();
  }

  void enqueue(ReminderRequest request) {
    _queue.add(request);
    if (!_isProcessing) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }

    _isProcessing = true;
    final request = _queue.removeAt(0);

    try {
      // 1. Trigger the native service
      switch (request.location) {
        case ReminderLocation.cursor:
          await CursorPillService.showPill(request.content);
          break;
        case ReminderLocation.island:
          await NotchHookService.showIsland(request.content);
          break;
        case ReminderLocation.tray:
          await TrayPillService.showPill(request.content);
          break;
      }

      // 2. Wait for the exact duration of the sequence (frames / 25fps)
      // We add an 800ms buffer (500ms for exit animation + 300ms gap)
      final durationMs = (request.content.totalFrames / 25 * 1000).toInt() + 800;
      await Future.delayed(Duration(milliseconds: durationMs));
      
    } catch (e) {
      print('Error processing reminder: $e');
    } finally {
      // Small safety gap before starting next in line
      await Future.delayed(const Duration(milliseconds: 100));
      _processQueue();
    }
  }
}
