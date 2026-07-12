/// Centralized constants for all platform channel names and method names.
/// Mirrors lib/core/constants/platform_channels.dart — keep in sync.
enum PlatformChannels {
    // ── Channel names ────────────────────────────────────────────
    static let notchHook = "app.keti/notch_hook"
    static let cursorPill = "app.keti/cursor_pill"
    static let trayPill = "app.keti/tray_pill"

    // ── Method names (notch_hook) ────────────────────────────────
    static let methodShowIsland = "showIsland"

    // ── Method names (cursor_pill) ───────────────────────────────
    static let methodShowCursorPill = "showPill"

    // ── Method names (tray_pill) ─────────────────────────────────
    static let methodShowTrayPill = "showPill"

    // ── Argument keys ─────────────────────────────────────────────
    static let keyMessage = "message"
    static let keyResourceName = "resourceName"
}
