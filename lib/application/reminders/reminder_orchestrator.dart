import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/compliance_card_service.dart';
import '../../core/services/cursor_pill_service.dart';
import '../../core/services/notch_hook_service.dart';
import '../../core/services/reminder_channels.dart';
import '../../core/services/tray_pill_service.dart';
import '../../domain/reminders/reminder_content.dart';
import '../../domain/study/study_enums.dart';

part 'reminder_orchestrator.g.dart';

@riverpod
ReminderOrchestrator reminderOrchestrator(Ref ref) => ReminderOrchestrator();

/// Lifecycle callbacks for one reminder's full sequence. Each is awaited in
/// turn; the orchestrator guarantees order and exactly-one-terminal-outcome.
typedef ReminderCallback = Future<void> Function();
typedef ReminderFailureCallback = Future<void> Function(String reason);
typedef ReminderOutcomeCallback = Future<void> Function(String action);

/// Drives the full per-reminder chain (plan §5.2):
///
/// ```
/// show reminder (placement)      → onDelivered  (native onShown confirmed)
/// hold for visibilityMs          → onReminderHidden
/// show compliance card top-right → onCardShown
/// button press / card timeout    → onCardAnswered(action) | onCardTimedOut
/// any technical failure          → onFailed(reason) — sequence aborts
/// ```
///
/// This is the single place the sequence exists — study sessions and the
/// (journal-only) test mode both go through it, so behavior can't diverge.
class ReminderOrchestrator {
  Future<void> runReminderSequence({
    required String reminderId,
    required ReminderContent content,
    required Placement placement,
    required String question,
    required String button1Text,
    required String button2Text,
    required int visibilityMs,
    required int cardTimeoutMs,
    required ReminderCallback onDelivered,
    required ReminderCallback onReminderHidden,
    required ReminderCallback onCardShown,
    required ReminderOutcomeCallback onCardAnswered,
    required ReminderCallback onCardTimedOut,
    required ReminderFailureCallback onFailed,
  }) async {
    ReminderChannels.ensureRegistered();
    try {
      // Register the waiter BEFORE triggering the show method to avoid
      // losing the onShown signal if it arrives during the invokeMethod await.
      final shownFuture = ReminderChannels.waitForShown(reminderId);

      await _showPlacement(
        reminderId: reminderId,
        content: content,
        placement: placement,
        visibilityMs: visibilityMs,
      );

      final confirmed = await shownFuture;
      if (!confirmed) {
        await onFailed('shown_not_confirmed:$placement');
        return;
      }
      await onDelivered();

      await ReminderChannels.waitForHidden(
        reminderId,
        window: Duration(milliseconds: visibilityMs),
      );
      await onReminderHidden();

      await ComplianceCardService.show(
        reminderId: reminderId,
        question: question,
        button1Text: button1Text,
        button2Text: button2Text,
        timeoutMs: cardTimeoutMs,
      );
      await onCardShown();

      final outcome = await ReminderChannels.waitForCardOutcome(
        reminderId,
        timeout: Duration(milliseconds: cardTimeoutMs + 10000),
      );
      if (outcome == 'timeout') {
        await onCardTimedOut();
      } else {
        await onCardAnswered(outcome);
      }
    } catch (e) {
      await onFailed(_failureReason(e));
    }
  }

  /// Keeps the service-provided detail (e.g. `cursor_pill not available on
  /// this platform`) instead of reducing failures to a bare type name.
  static String _failureReason(Object error) {
    if (error is StateError) return error.message;
    return 'orchestrator:${error.runtimeType}';
  }

  Future<void> _showPlacement({
    required String reminderId,
    required ReminderContent content,
    required Placement placement,
    required int visibilityMs,
  }) {
    return switch (placement) {
      Placement.cursorProximate => CursorPillService.showPill(
          content,
          reminderId: reminderId,
          visibilityMs: visibilityMs,
        ),
      Placement.notchCard => NotchHookService.showIsland(
          content,
          reminderId: reminderId,
          visibilityMs: visibilityMs,
        ),
      Placement.systemTray => TrayPillService.showPill(
          content,
          reminderId: reminderId,
          visibilityMs: visibilityMs,
        ),
    };
  }
}
