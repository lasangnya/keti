import 'package:flutter/services.dart';
import 'package:keti/core/constants/platform_channels.dart';

class ComplianceCardService {
  static const _channel = MethodChannel(PlatformChannels.complianceCard);

  static Future<void> show({
    required String title,
    required String button1Text,
    required String button2Text,
  }) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == PlatformChannels.methodOnButtonClicked) {
        final clickedButton = call.arguments as String;
        print('--- Compliance Card Clicked: $clickedButton ---');
      }
    });

    try {
      await _channel.invokeMethod(PlatformChannels.methodShowComplianceCard, {
        PlatformChannels.keyTitle: title,
        PlatformChannels.keyButton1Text: button1Text,
        PlatformChannels.keyButton2Text: button2Text,
      });
    } on PlatformException catch (e) {
      print("Failed to show compliance card: ${e.message}");
    }
  }
}
