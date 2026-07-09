import 'package:flutter/services.dart';
import 'package:keti/core/constants/platform_channels.dart';

class TrayPillService {
  static const _channel = MethodChannel(PlatformChannels.trayPill);

  static Future<void> showPill() async {
    try {
      await _channel.invokeMethod(PlatformChannels.methodShowTrayPill);
    } on PlatformException catch (e) {
      print("Failed to show tray pill: ${e.message}");
    }
  }
}
