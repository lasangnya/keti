import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../constants/platform_channels.dart';

/// Launches a second instance of this app in **researcher mode** so the
/// participant and researcher can run in parallel windows/processes.
///
/// The researcher flag is communicated via a **marker file** rather than
/// process env/argv: env vars and `--args` are not reliably propagated to a
/// second instance when the app is hosted by `flutter run` or LaunchServices.
/// [launch] writes the marker, opens a fresh instance via `open -n`, and the
/// new instance reads+deletes the marker at startup (see [main]).
///
/// Both instances share the same Firestore project, so admin actions
/// (e.g. Activate Day 2) are picked up by the participant window's auto-check.
class ResearcherLauncher {
  /// Legacy env/argv flags, kept for direct launches.
  static const flag = '--researcher';
  static const envFlag = 'KETI_RESEARCHER';

  /// Marker file the second instance checks at startup.
  static String get markerPath =>
      '${Directory.systemTemp.path}/keti_researcher_request';

  /// True when the current process IS the researcher window.
  static bool get isResearcherWindow => !kIsWeb &&
      (Platform.executableArguments.contains(flag) ||
          Platform.environment[envFlag] == '1' ||
          _consumeMarker());

  static bool _consumeMarker() {
    try {
      final marker = File(markerPath);
      if (marker.existsSync()) {
        marker.deleteSync();
        debugPrint('ResearcherLauncher: researcher marker consumed');
        return true;
      }
    } catch (e) {
      debugPrint('ResearcherLauncher: marker check failed: $e');
    }
    return false;
  }

  /// Spawns a second instance directly with the researcher env flag.
  ///
  /// `open -n` (LaunchServices) is NOT used: when the app is hosted by
  /// `flutter run`, LaunchServices does not reliably start a second process
  /// with our flags. Direct spawn always passes env reliably; the black
  /// window that direct spawn used to cause is fixed by the native
  /// `NSApp.activate` in `AppDelegate.applicationDidFinishLaunching`.
  ///
  /// Returns false (and logs) when the launch fails.
  static Future<bool> launch() async {
    if (kIsWeb) return false;
    try {
      // Marker as well — belt and braces with the env flag.
      File(markerPath).writeAsStringSync('1');
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
