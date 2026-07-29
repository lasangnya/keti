import 'package:flutter/services.dart';
import 'package:keti/core/constants/platform_channels.dart';
import '../../domain/reminders/reminder_content.dart';

class TrayPillService {
  static const _channel = MethodChannel(PlatformChannels.trayPill);

  /// Shows the system-tray pill and its dropped card. The native side holds
  /// them for [visibilityMs] and reports `onShown`/`onHidden` with
  /// [reminderId].
  static Future<void> showPill(
    ReminderContent content, {
    required String reminderId,
    required int visibilityMs,
  }) async {
    try {
      await _channel.invokeMethod(PlatformChannels.methodShowTrayPill, {
        PlatformChannels.keyReminderId: reminderId,
        PlatformChannels.keyMessage: content.message,
        PlatformChannels.keyResourceName: content.trayResource,
        PlatformChannels.keyWidth: content.trayWidth,
        PlatformChannels.keyHeight: content.trayHeight,
        PlatformChannels.keyTotalFrames: content.totalFrames,
        PlatformChannels.keyVisibilityMs: visibilityMs,
      });
    } on PlatformException catch (e) {
      throw StateError('tray_pill platform failure: ${e.message}');
    } on MissingPluginException {
      throw StateError('tray_pill not available on this platform');
    }
  }
}
