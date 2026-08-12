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

  /// Writes the marker and opens a second instance via LaunchServices
  /// (`open -n`), which forces a new instance and properly activates the
  /// window so the Flutter surface renders (spawning the raw executable
  /// directly produces a black window on macOS).
  ///
  /// Returns false (and logs) when the launch fails.
  static Future<bool> launch() async {
    if (kIsWeb) return false;
    try {
      final bundle = _appBundlePath(Platform.resolvedExecutable);
      if (bundle == null) {
        debugPrint(
            'ResearcherLauncher: could not locate the .app bundle for '
            '${Platform.resolvedExecutable}');
        return false;
      }
      // Marker first — the new instance reads it before/independent of any
      // env/argv quirks of the launch mechanism.
      File(markerPath).writeAsStringSync('1');
      final result = await Process.run('open', ['-n', bundle]);
      if (result.exitCode != 0) {
        debugPrint('ResearcherLauncher: open failed (${result.exitCode}): '
            '${result.stderr}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('ResearcherLauncher: failed to launch: $e');
      return false;
    }
  }

  /// Walks up from the executable to the enclosing `*.app` bundle.
  /// `resolvedExecutable` is `…/keti.app/Contents/MacOS/keti`, so the bundle
  /// is three levels up.
  static String? _appBundlePath(String executablePath) {
    var dir = File(executablePath).parent;
    for (var i = 0; i < 6; i++) {
      if (dir.path.endsWith('.app') && dir.existsSync()) return dir.path;
      dir = dir.parent;
    }
    return null;
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
