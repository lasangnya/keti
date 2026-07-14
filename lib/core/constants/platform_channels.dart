/// Centralized constants for all platform channel names and method names.
/// Keeps Dart and Swift sides in sync — mirror in macos/Runner/PlatformChannels.swift.
class PlatformChannels {
  PlatformChannels._();

  // ── Channel names ──────────────────────────────────────────────
  static const String notchHook = 'app.keti/notch_hook';
  static const String cursorPill = 'app.keti/cursor_pill';
  static const String trayPill = 'app.keti/tray_pill';

  // ── Method names (Shared) ──────────────────────────────────────
  static const String methodOnDismissed = 'onDismissed';

  // ── Method names (notch_hook) ──────────────────────────────────
  static const String methodShowIsland = 'showIsland';

  // ── Method names (cursor_pill) ─────────────────────────────────
  static const String methodShowCursorPill = 'showPill';

  // ── Method names (tray_pill) ───────────────────────────────────
  static const String methodShowTrayPill = 'showPill';

  // ── Argument keys (notch_hook) ─────────────────────────────────
  static const String keyMessage = 'message';

  // ── Content resource name (notch_hook) ─────────────────────────────────
  static const String keyResourceName = 'resourceName';
  static const String keyWidth = 'width';
  static const String keyHeight = 'height';
  static const String keyOffsetX = 'offsetX';
  static const String keyOffsetY = 'offsetY';
  static const String keyTotalFrames = 'totalFrames';
}
