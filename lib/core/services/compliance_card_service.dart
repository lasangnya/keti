import 'package:flutter/services.dart';
import 'package:keti/core/constants/platform_channels.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'compliance_card_service.g.dart';

@riverpod
ComplianceCardService complianceCardService(Ref ref) => ComplianceCardService();

/// Shows the uniform compliance card (plan §5.4): same look, position
/// (top-right of the screen), and behavior for every reminder, placement,
/// style, and participant. Outcomes arrive via [ReminderChannels] as
/// `completed`, `dismissed`, or a card timeout.
class ComplianceCardService {
  static const _channel = MethodChannel(PlatformChannels.complianceCard);

  Future<void> show({
    required String reminderId,
    required String question,
    required String button1Text,
    required String button2Text,
    required int timeoutMs,
  }) async {
    try {
      await _channel.invokeMethod(PlatformChannels.methodShowComplianceCard, {
        PlatformChannels.keyReminderId: reminderId,
        PlatformChannels.keyQuestion: question,
        PlatformChannels.keyButton1Text: button1Text,
        PlatformChannels.keyButton2Text: button2Text,
        PlatformChannels.keyTimeoutMs: timeoutMs,
      });
    } on PlatformException catch (e) {
      throw StateError('compliance_card platform failure: ${e.message}');
    } on MissingPluginException {
      throw StateError('compliance_card not available on this platform');
    }
  }
}
