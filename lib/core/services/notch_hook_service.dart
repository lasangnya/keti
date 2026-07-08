import 'package:flutter/services.dart';

class NotchHookService {

  static const _channel = MethodChannel('app.keti/notch_hook'); // The channel name should be the same as MainFlutterWindow.swift

  static Future<void> showIsland(String message) async {
    try {
      await _channel.invokeMethod('showIsland', {'message': message});
    } on PlatformException catch (e) {
      print("Failed to show island: ${e.message}");
    }
  }
}