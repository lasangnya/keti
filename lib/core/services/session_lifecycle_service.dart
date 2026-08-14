import 'dart:ui' show AppExitResponse, AppExitType;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:keti/core/constants/platform_channels.dart';

/// Tells the native host whether a study session is currently active.
///
/// While active (plan §6.5), macOS keeps the process alive when the main
/// window closes (`applicationShouldTerminateAfterLastWindowClosed` → false)
/// and App Nap is suppressed via `ProcessInfo.beginActivity(.userInitiated)`,
/// so the scheduler keeps firing during a 2-hour session.
class SessionLifecycleService {
  static const _channel = MethodChannel(PlatformChannels.sessionLifecycle);

  static Future<void> setSessionActive(bool active) async {
    try {
      await _channel
          .invokeMethod(PlatformChannels.methodSetSessionActive, active)
          // A native hang must never freeze a study session.
          .timeout(const Duration(seconds: 2), onTimeout: () {});
    } on PlatformException {
      // Native side rejected the call — session continues regardless.
    } on MissingPluginException {
      // No native handler on this platform (Windows/Linux).
    }
  }

  /// Terminates the host application (participant Exit button).
  ///
  /// Goes through the engine's `System.exitApplication` path: a raw
  /// `NSApp.terminate` is canceled by `FlutterAppDelegate
  /// .applicationShouldTerminate` unless the engine termination handler
  /// approved the exit. `AppExitType.required` exits without querying the
  /// app, so nothing can swallow it.
  static Future<void> exitApp() async {
    try {
      await ServicesBinding.instance
          .exitApplication(AppExitType.required, 0)
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => AppExitResponse.cancel,
          );
    } catch (e) {
      // In production the engine exits immediately; a rejection only
      // surfaces on platforms/test bindings that refuse the request.
      debugPrint('App exit request rejected: $e');
    }
  }
}
