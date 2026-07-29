import 'package:flutter/services.dart';
import 'package:keti/core/constants/platform_channels.dart';
import '../../domain/reminders/reminder_content.dart';

class NotchHookService {
  static const _channel = MethodChannel(PlatformChannels.notchHook);

  /// Shows the top-center notch card. The native side holds it for
  /// [visibilityMs] and reports `onShown`/`onHidden` with [reminderId].
  static Future<void> showIsland(
    ReminderContent content, {
    required String reminderId,
    required int visibilityMs,
  }) async {
    try {
      await _channel.invokeMethod(PlatformChannels.methodShowIsland, {
        PlatformChannels.keyReminderId: reminderId,
        PlatformChannels.keyMessage: content.message,
        PlatformChannels.keyResourceName: content.notchResource,
        PlatformChannels.keyWidth: content.notchWidth,
        PlatformChannels.keyHeight: content.notchHeight,
        PlatformChannels.keyTotalFrames: content.totalFrames,
        PlatformChannels.keyVisibilityMs: visibilityMs,
      });
    } on PlatformException catch (e) {
      throw StateError('notch_hook platform failure: ${e.message}');
    } on MissingPluginException {
      throw StateError('notch_hook not available on this platform');
    }
  }
}
