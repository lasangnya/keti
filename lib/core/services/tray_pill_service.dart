import 'package:flutter/services.dart';
import 'package:keti/core/constants/platform_channels.dart';
import '../../domain/reminders/reminder_content.dart';

class TrayPillService {
  static const _channel = MethodChannel(PlatformChannels.trayPill);

  static Future<void> showPill(ReminderContent content) async {
    try {
      await _channel.invokeMethod(PlatformChannels.methodShowTrayPill, {
        PlatformChannels.keyMessage: content.message,
        PlatformChannels.keyResourceName: content.trayResource,
        PlatformChannels.keyWidth: content.trayWidth,
        PlatformChannels.keyHeight: content.trayHeight,
      });
    } on PlatformException catch (e) {
      print("Failed to show tray pill: ${e.message}");
    }
  }
}
