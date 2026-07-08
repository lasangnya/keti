/// Centralized constants for all platform channel names and method names.
/// Keeps Dart and Swift sides in sync — mirror in macos/Runner/PlatformChannels.swift.
class PlatformChannels {
  PlatformChannels._();

  // ── Channel names ──────────────────────────────────────────────
  static const String notchHook = 'app.keti/notch_hook';
  static const String cursorPill = 'app.keti/cursor_pill';

  // ── Method names (notch_hook) ──────────────────────────────────
  static const String methodShowIsland = 'showIsland';

  // ── Method names (cursor_pill) ─────────────────────────────────
  static const String methodShowCursorPill = 'showPill';

  // ── Argument keys (notch_hook) ─────────────────────────────────
  static const String keyMessage = 'message';
}
