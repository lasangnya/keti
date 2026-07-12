import 'package:flutter/services.dart';
import 'package:keti/core/constants/platform_channels.dart';
import 'package:keti/domain/reminders/reminder_content.dart';

class NotchHookService {
  static const _channel = MethodChannel(PlatformChannels.notchHook);

  static Future<void> showIsland(ReminderContent content) async {
    try {
      await _channel.invokeMethod(PlatformChannels.methodShowIsland, {
        PlatformChannels.keyMessage: content.message,
        PlatformChannels.keyResourceName: content.notchResource,
      });
    } on PlatformException catch (e) {
      print("Failed to show island: ${e.message}");
    }
  }
}
