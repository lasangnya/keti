import 'package:flutter/services.dart';
import 'package:keti/core/constants/platform_channels.dart';

class CursorPillService {
  static const _channel = MethodChannel(PlatformChannels.cursorPill);

  static Future<void> showPill() async {
    try {
      await _channel.invokeMethod(PlatformChannels.methodShowCursorPill);
    } on PlatformException catch (e) {
      print("Failed to show cursor pill: ${e.message}");
    }
  }
}
