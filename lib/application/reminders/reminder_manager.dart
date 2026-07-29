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

  int _testReminderCounter = 0;

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

    // Test-mode displays are fire-and-forget; the study sequence (reminder +
    // compliance card) is driven by the ReminderOrchestrator instead.
    final visibilityMs = (request.content.totalFrames / 25 * 1000).toInt() + 800;
    final reminderId = 'test-${_testReminderCounter++}';

    try {
      switch (request.location) {
        case ReminderLocation.cursor:
          await CursorPillService.showPill(request.content,
              reminderId: reminderId, visibilityMs: visibilityMs);
          break;
        case ReminderLocation.island:
          await NotchHookService.showIsland(request.content,
              reminderId: reminderId, visibilityMs: visibilityMs);
          break;
        case ReminderLocation.tray:
          await TrayPillService.showPill(request.content,
              reminderId: reminderId, visibilityMs: visibilityMs);
          break;
      }

      // Wait out the visibility window before dequeuing the next in line.
      await Future.delayed(Duration(milliseconds: visibilityMs));

    } catch (e) {
      print('Error processing reminder: $e');
    } finally {
      // Small safety gap before starting next in line
      await Future.delayed(const Duration(milliseconds: 100));
      _processQueue();
    }
  }
}
