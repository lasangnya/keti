/// Centralized constants for all platform channel names and method names.
/// Mirrors lib/core/constants/platform_channels.dart — keep in sync.
enum PlatformChannels {
    // ── Channel names ────────────────────────────────────────────
    static let notchHook = "app.keti/notch_hook"

    // ── Method names (notch_hook) ────────────────────────────────
    static let methodShowIsland = "showIsland"

    // ── Argument keys (notch_hook) ───────────────────────────────
    static let keyMessage = "message"
}
