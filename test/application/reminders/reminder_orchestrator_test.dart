import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keti/application/reminders/reminder_orchestrator.dart';
import 'package:keti/core/constants/platform_channels.dart';
import 'package:keti/domain/study/reminder_content_resolver.dart';
import 'package:keti/domain/study/study_enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final capturedPlacement = <MethodCall>[];
  final capturedCard = <MethodCall>[];

  setUp(() {
    capturedPlacement.clear();
    capturedCard.clear();
    for (final channel in [
      PlatformChannels.cursorPill,
      PlatformChannels.notchHook,
      PlatformChannels.trayPill,
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (call) async {
          capturedPlacement.add(call);
          return null;
        },
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel(PlatformChannels.complianceCard),
      (call) async {
        capturedCard.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    for (final channel in [
      PlatformChannels.cursorPill,
      PlatformChannels.notchHook,
      PlatformChannels.trayPill,
      PlatformChannels.complianceCard,
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), null);
    }
  });

  /// Simulates a native→Dart callback on [channel].
  Future<void> emitNative(
      String channel, String method, Object? arguments) async {
    await messenger.handlePlatformMessage(
      channel,
      const StandardMethodCodec()
          .encodeMethodCall(MethodCall(method, arguments)),
      (data) {},
    );
  }

  final content = const ReminderContentResolver()
      .resolve(ReminderKind.hydration, PresentationStyle.ambient)
      .content;

  // Short timings so the real-timer test completes quickly: the card
  // appears 10ms after shown and auto-dismisses after 30ms without a
  // response.
  const cardDelayMs = 10;
  const cardTimeoutMs = 30;

  Future<void> startSequence(List<String> stages) =>
      ReminderOrchestrator().runReminderSequence(
        reminderId: 'reminder01',
        content: content,
        placement: Placement.cursorProximate,
        question: 'Did you drink some water?',
        button1Text: 'Done',
        button2Text: 'Not now',
        visibilityMs: 45000,
        cardDelayMs: cardDelayMs,
        cardTimeoutMs: cardTimeoutMs,
        onDelivered: () async => stages.add('delivered'),
        onReminderHidden: () async => stages.add('hidden'),
        onCardShown: () async => stages.add('cardShown'),
        onCardAnswered: (action) async => stages.add('answered:$action'),
        onCardTimedOut: () async => stages.add('timedOut'),
        onFailed: (reason) async => stages.add('failed:$reason'),
      );

  test('card appears cardDelayMs after shown and carries correct args',
      () async {
    final stages = <String>[];
    final sequence = startSequence(stages);
    await pumpEventQueue();

    // Dart → native: show call carries reminderId + visibilityMs.
    expect(capturedPlacement, hasLength(1));
    final showArgs = capturedPlacement.single.arguments as Map;
    expect(showArgs[PlatformChannels.keyReminderId], 'reminder01');
    expect(showArgs[PlatformChannels.keyVisibilityMs], 45000);

    // Native confirms shown → delivered. Card NOT shown yet (delay pending).
    await emitNative(
        PlatformChannels.cursorPill, PlatformChannels.methodOnShown, 'reminder01');
    await pumpEventQueue();
    expect(stages, ['delivered']);
    expect(capturedCard, isEmpty);

    // After the delay the compliance card appears.
    await Future.delayed(Duration(milliseconds: cardDelayMs + 5));
    await pumpEventQueue();
    expect(stages, ['delivered', 'cardShown']);
    expect(capturedCard, hasLength(1));
    final cardArgs = capturedCard.single.arguments as Map;
    expect(cardArgs[PlatformChannels.keyReminderId], 'reminder01');
    expect(cardArgs[PlatformChannels.keyQuestion], 'Did you drink some water?');
    expect(cardArgs[PlatformChannels.keyTimeoutMs], cardTimeoutMs);

    // Reminder hides independently (before the card times out here).
    await emitNative(
        PlatformChannels.cursorPill, PlatformChannels.methodOnHidden, 'reminder01');
    await pumpEventQueue();
    expect(stages, contains('hidden'));

    // Participant taps "Done" → completed.
    await emitNative(PlatformChannels.complianceCard,
        PlatformChannels.methodOnCardAction, {
      PlatformChannels.keyReminderId: 'reminder01',
      PlatformChannels.keyAction: 'completed',
    });
    await sequence;
    expect(stages, ['delivered', 'cardShown', 'hidden', 'answered:completed']);
  });

  test('dismiss action maps to dismissed outcome', () async {
    final stages = <String>[];
    final sequence = startSequence(stages);
    await pumpEventQueue();
    await emitNative(
        PlatformChannels.cursorPill, PlatformChannels.methodOnShown, 'reminder01');
    await pumpEventQueue();
    await Future.delayed(Duration(milliseconds: cardDelayMs + 5));
    await pumpEventQueue();
    await emitNative(PlatformChannels.complianceCard,
        PlatformChannels.methodOnCardAction, {
      PlatformChannels.keyReminderId: 'reminder01',
      PlatformChannels.keyAction: 'dismissed',
    });
    await sequence;
    expect(stages.last, 'answered:dismissed');
  });

  test('card auto-dismiss (timeout) produces the timedOut outcome', () async {
    final stages = <String>[];
    final sequence = startSequence(stages);
    await pumpEventQueue();
    await emitNative(
        PlatformChannels.cursorPill, PlatformChannels.methodOnShown, 'reminder01');
    await pumpEventQueue();
    await Future.delayed(Duration(milliseconds: cardDelayMs + 5));
    await pumpEventQueue();
    expect(stages, contains('cardShown'));

    // No response: the card times out after cardTimeoutMs.
    await emitNative(PlatformChannels.complianceCard,
        PlatformChannels.methodOnCardTimeout, 'reminder01');
    await sequence;
    expect(stages, contains('timedOut'));
  });

  test('platform failure aborts the chain with onFailed', () async {
    messenger.setMockMethodCallHandler(
      const MethodChannel(PlatformChannels.cursorPill),
      (call) async =>
          throw PlatformException(code: 'boom', message: 'native exploded'),
    );

    final stages = <String>[];
    await startSequence(stages);
    expect(stages, hasLength(1));
    expect(stages.single, startsWith('failed:'));
    expect(stages.single, contains('cursor_pill'));
  });
}
