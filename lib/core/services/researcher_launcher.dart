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
/// LaunchServices (`open -n`) is required: spawning the raw executable
/// directly starts the process without activation, the window server reports
/// it occluded, and the Flutter engine stops presenting frames — a black
/// window that in-process `NSApp.activate` cannot fix. LaunchServices
/// launches the new instance with system-granted activation.
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
  ///
  /// The first evaluation is cached: the marker file is one-shot (consumed on
  /// read), so evaluating this more than once — the startup diagnostics in
  /// `main()` and again when `runApp` builds the tree — must not lose it.
  static bool? _isResearcherWindow;

  static bool get isResearcherWindow {
    _isResearcherWindow ??= !kIsWeb &&
        (Platform.executableArguments.contains(flag) ||
            Platform.environment[envFlag] == '1' ||
            _consumeMarker());
    return _isResearcherWindow!;
  }

  /// Test hook: clears the cached flag so a test can re-evaluate from a
  /// clean state (the cache is process-global static state).
  @visibleForTesting
  static void resetCachedFlag() {
    _isResearcherWindow = null;
  }

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

  /// Opens a second instance of this app in **researcher mode** so the
  /// participant and researcher run in parallel.
  ///
  /// The researcher flag travels via the marker file, which the fresh
  /// instance consumes on startup — neither env vars nor argv are reliably
  /// visible to a directly-spawned second instance.
  ///
  /// macOS goes through LaunchServices (`open -n`) for system-granted
  /// activation; Windows/Linux spawn the same executable directly.
  ///
  /// Returns false (and logs) when the launch fails.
  static Future<bool> launch() async {
    if (kIsWeb) return false;
    try {
      // Marker first — the new instance reads it before/independent of any
      // env/argv quirks of the launch mechanism.
      File(markerPath).writeAsStringSync('1');

      if (Platform.isMacOS) {
        return _launchMacos();
      }
      return _launchNative();
    } catch (e) {
      debugPrint('ResearcherLauncher: failed to launch: $e');
      _clearMarker();
      return false;
    }
  }

  /// Launches a second instance through LaunchServices (`open -n`), which
  /// forces a new instance with system-granted activation — a directly
  /// spawned process is never activated, its window is reported occluded,
  /// and the Flutter surface stays black.
  static Future<bool> _launchMacos() async {
    final bundle = _appBundlePath(Platform.resolvedExecutable);
    if (bundle == null) {
      debugPrint('ResearcherLauncher: could not locate the .app bundle for '
          '${Platform.resolvedExecutable}');
      _clearMarker();
      return false;
    }
    final result = await Process.run('open', ['-n', bundle]);
    if (result.exitCode != 0) {
      debugPrint('ResearcherLauncher: open failed (${result.exitCode}): '
          '${result.stderr}');
      _clearMarker();
      return false;
    }
    return true;
  }

  /// Spawns a second instance of the current executable (Windows/Linux). The
  /// researcher flag is carried by the marker file, not argv — the fresh
  /// instance consumes it on startup.
  ///
  /// The parent's engine switches must not be inherited: `flutter run` passes
  /// debug flags (notably `start-paused` and `vm-service-port`) via
  /// `FLUTTER_ENGINE_SWITCH*` environment variables. A second instance that
  /// inherits `start-paused=true` waits for a debugger that never connects and
  /// never renders a frame, so no window appears.
  static Future<bool> _launchNative() async {
    final environment = Map<String, String>.from(Platform.environment)
      ..removeWhere((key, _) => key.startsWith('FLUTTER_ENGINE_SWITCH'));
    final process = await Process.start(
      Platform.resolvedExecutable,
      const <String>[],
      environment: environment,
      includeParentEnvironment: false,
      mode: ProcessStartMode.detached,
    );
    return process.pid > 0;
  }

  /// Removes a stale marker so a later participant launch can't consume it
  /// and accidentally boot into admin mode.
  static void _clearMarker() {
    try {
      final marker = File(markerPath);
      if (marker.existsSync()) {
        marker.deleteSync();
      }
    } catch (_) {
      // Best effort — nothing else we can do if the marker can't be removed.
    }
  }

  /// Walks up from the executable to the enclosing `*.app` bundle.
  /// `resolvedExecutable` is `…/keti.app/Contents/MacOS/keti`, so the bundle
  /// is two levels up.
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
