import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../constants/platform_channels.dart';

/// Launches a second instance of this app in **researcher mode** so the
/// participant and researcher can run in parallel windows/processes.
///
/// The new process boots into the admin UI because [main] checks the
/// `KETI_RESEARCHER` environment variable (see `main.dart`). Both instances
/// share the same Firestore project, so admin actions (e.g. Activate Day 2)
/// are picked up by the participant window's auto-check.
class ResearcherLauncher {
  /// Environment flag the second instance checks at startup.
  static const envFlag = 'KETI_RESEARCHER';

  /// True when the current process IS the researcher window.
  static bool get isResearcherWindow =>
      !kIsWeb && Platform.environment[envFlag] == '1';

  /// Spawns a detached second instance of this app with [envFlag] set.
  /// Returns false (and logs) when the launch fails.
  static Future<bool> launch() async {
    if (kIsWeb) return false;
    try {
      await Process.start(
        Platform.resolvedExecutable,
        const <String>[],
        environment: {
          ...Platform.environment,
          envFlag: '1',
        },
        mode: ProcessStartMode.detached,
      );
      return true;
    } catch (e) {
      debugPrint('ResearcherLauncher: failed to launch: $e');
      return false;
    }
  }

  /// Closes the current window (used by the researcher instance's
  /// "Close window" action — closing the only window terminates this
  /// dedicated researcher process). Best-effort: no-op where the native
  /// handler is missing (e.g. test host).
  static Future<void> closeWindow() async {
    if (kIsWeb) return;
    try {
      await const MethodChannel(PlatformChannels.sessionLifecycle)
          .invokeMethod(PlatformChannels.methodCloseWindow);
    } catch (e) {
      debugPrint('ResearcherLauncher: closeWindow unavailable: $e');
    }
  }
}
