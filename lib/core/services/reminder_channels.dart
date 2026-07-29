import 'dart:async';

import 'package:flutter/services.dart';
import 'package:keti/core/constants/platform_channels.dart';

/// Routing hub for native→Dart reminder callbacks (plan §5.4 channel
/// contract v2).
///
/// The three placement channels report `onShown`/`onHidden` keyed by
/// reminderId; the compliance-card channel reports `onCardAction`/
/// `onCardTimeout`. Callers register intent to wait per reminderId and the
/// single persistent handler routes callbacks to the matching completer.
class ReminderChannels {
  ReminderChannels._();

  static bool _registered = false;

  static final _shownWaiters = <String, Completer<void>>{};
  static final _hiddenWaiters = <String, Completer<void>>{};
  static final _cardOutcomeWaiters = <String, Completer<String>>{};

  /// Registers the persistent method-call handlers once per app lifetime.
  static void ensureRegistered() {
    if (_registered) return;
    _registered = true;

    const MethodChannel(PlatformChannels.cursorPill)
        .setMethodCallHandler((call) async => _routePlacementCall(call));
    const MethodChannel(PlatformChannels.notchHook)
        .setMethodCallHandler((call) async => _routePlacementCall(call));
    const MethodChannel(PlatformChannels.trayPill)
        .setMethodCallHandler((call) async => _routePlacementCall(call));
    const MethodChannel(PlatformChannels.complianceCard)
        .setMethodCallHandler((call) async => _routeCardCall(call));
  }

  static void _routePlacementCall(MethodCall call) {
    final reminderId = call.arguments;
    if (reminderId is! String) return;
    switch (call.method) {
      case PlatformChannels.methodOnShown:
        _shownWaiters.remove(reminderId)?.complete();
      case PlatformChannels.methodOnHidden:
        _hiddenWaiters.remove(reminderId)?.complete();
    }
  }

  static void _routeCardCall(MethodCall call) {
    switch (call.method) {
      case PlatformChannels.methodOnCardAction:
        final args = call.arguments;
        if (args is! Map) return;
        final reminderId = args[PlatformChannels.keyReminderId];
        final action = args[PlatformChannels.keyAction];
        if (reminderId is String && action is String) {
          _cardOutcomeWaiters.remove(reminderId)?.complete(action);
        }
      case PlatformChannels.methodOnCardTimeout:
        final reminderId = call.arguments;
        if (reminderId is String) {
          _cardOutcomeWaiters.remove(reminderId)?.complete('timeout');
        }
    }
  }

  /// Waits for the native side to confirm the reminder is on screen.
  /// Returns false when no confirmation arrives within [timeout] — treated
  /// as a delivery failure by the caller.
  static Future<bool> waitForShown(
    String reminderId, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    ensureRegistered();
    final completer = Completer<void>();
    _shownWaiters[reminderId] = completer;
    try {
      await completer.future.timeout(timeout);
      return true;
    } on TimeoutException {
      _shownWaiters.remove(reminderId);
      return false;
    }
  }

  /// Waits out the reminder's visibility window. Returns as soon as the
  /// native side reports the panel hidden, or when [window] has elapsed —
  /// whichever comes first — so a missing native callback can never stall
  /// the sequence.
  static Future<void> waitForHidden(
    String reminderId, {
    required Duration window,
  }) async {
    ensureRegistered();
    final completer = Completer<void>();
    _hiddenWaiters[reminderId] = completer;
    await Future.any([
      completer.future,
      Future.delayed(window + const Duration(seconds: 5)),
    ]);
    _hiddenWaiters.remove(reminderId);
  }

  /// Waits for the compliance-card outcome: `completed`, `dismissed`, or
  /// `timeout`. The native side times out on its own; the extra delay cap
  /// here is only a safety net.
  static Future<String> waitForCardOutcome(
    String reminderId, {
    required Duration timeout,
  }) async {
    ensureRegistered();
    final completer = Completer<String>();
    _cardOutcomeWaiters[reminderId] = completer;
    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      _cardOutcomeWaiters.remove(reminderId);
      return 'timeout';
    }
  }

  /// Test seam: drop all waiters.
  static void debugReset() {
    _shownWaiters.clear();
    _hiddenWaiters.clear();
    _cardOutcomeWaiters.clear();
  }
}
