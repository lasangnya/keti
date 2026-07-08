/// Centralized constants for all platform channel names and method names.
/// Keeps Dart and Swift sides in sync — mirror in macos/Runner/PlatformChannels.swift.
class PlatformChannels {
  PlatformChannels._();

  // ── Channel names ──────────────────────────────────────────────
  static const String notchHook = 'app.keti/notch_hook';

  // ── Method names (notch_hook) ──────────────────────────────────
  static const String methodShowIsland = 'showIsland';

  // ── Argument keys (notch_hook) ─────────────────────────────────
  static const String keyMessage = 'message';
}
