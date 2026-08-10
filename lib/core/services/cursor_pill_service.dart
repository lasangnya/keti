import 'package:flutter/services.dart';
import 'package:keti/core/constants/platform_channels.dart';
import '../../domain/reminders/reminder_content.dart';

class CursorPillService {
  static const _channel = MethodChannel(PlatformChannels.cursorPill);

  /// Shows the cursor-proximate pill. The native side holds it on screen for
  /// [visibilityMs] and reports `onShown`/`onHidden` with [reminderId] back
  /// through [ReminderChannels].
  static Future<void> showPill(
    ReminderContent content, {
    required String reminderId,
    required int visibilityMs,
  }) async {
    try {
      await _channel.invokeMethod(PlatformChannels.methodShowCursorPill, {
        PlatformChannels.keyReminderId: reminderId,
        PlatformChannels.keyMessage: content.message,
        PlatformChannels.keyResourceName: content.cursorResource,
        PlatformChannels.keyWidth: content.cursorWidth,
        PlatformChannels.keyHeight: content.cursorHeight,
        PlatformChannels.keyOffsetX: content.cursorOffsetX,
        PlatformChannels.keyOffsetY: content.cursorOffsetY,
        PlatformChannels.keyTotalFrames: content.totalFrames,
        PlatformChannels.keyVisibilityMs: visibilityMs,
      });
    } on PlatformException catch (e) {
      throw StateError('cursor_pill platform failure: ${e.message}');
    } on MissingPluginException {
      throw StateError('cursor_pill not available on this platform');
    }
  }
}
