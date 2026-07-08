import 'package:flutter/services.dart';
import 'package:keti/core/constants/platform_channels.dart';

class NotchHookService {
  static const _channel = MethodChannel(PlatformChannels.notchHook);

  static Future<void> showIsland(String message) async {
    try {
      await _channel.invokeMethod(
        PlatformChannels.methodShowIsland,
        {PlatformChannels.keyMessage: message},
      );
    } on PlatformException catch (e) {
      print("Failed to show island: ${e.message}");
    }
  }
}