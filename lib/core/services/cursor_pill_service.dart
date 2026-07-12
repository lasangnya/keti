import 'package:flutter/services.dart';
import 'package:keti/core/constants/platform_channels.dart';
import '../../domain/reminders/reminder_content.dart';

class CursorPillService {
  static const _channel = MethodChannel(PlatformChannels.cursorPill);

  static Future<void> showPill(ReminderContent content) async {
    try {
      await _channel.invokeMethod(PlatformChannels.methodShowCursorPill, {
        PlatformChannels.keyMessage: content.message,
        PlatformChannels.keyResourceName: content.cursorResource,
      });
    } on PlatformException catch (e) {
      print("Failed to show cursor pill: ${e.message}");
    }
  }
}
