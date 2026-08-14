/// Centralized constants for all platform channel names and method names.
/// Mirrors lib/core/constants/platform_channels.dart — keep in sync.
enum PlatformChannels {
    // ── Channel names ────────────────────────────────────────────
    static let notchHook = "app.keti/notch_hook"
    static let cursorPill = "app.keti/cursor_pill"
    static let trayPill = "app.keti/tray_pill"
    static let complianceCard = "app.keti/compliance_card"
    static let sessionLifecycle = "app.keti/session_lifecycle"

    // ── Method names (Shared) ──────────────────────────────────────
    static let methodOnDismissed = "onDismissed"
    static let methodOnButtonClicked = "onButtonClicked"
    static let methodOnShown = "onShown"
    static let methodOnHidden = "onHidden"
    static let methodOnCardAction = "onCardAction"
    static let methodOnCardTimeout = "onCardTimeout"

    // ── Method names (notch_hook) ────────────────────────────────
    static let methodShowIsland = "showIsland"

    // ── Method names (cursor_pill) ───────────────────────────────
    static let methodShowCursorPill = "showPill"

    // ── Method names (tray_pill) ─────────────────────────────────
    static let methodShowTrayPill = "showPill"

    // ── Method names (compliance_card) ───────────────────────────
    static let methodShowComplianceCard = "showComplianceCard"

    // ── Method names (session_lifecycle) ─────────────────────────
    static let methodSetSessionActive = "setSessionActive"
    static let methodCloseWindow = "closeWindow"
    static let methodExitApp = "exitApp"

    // ── Argument keys ─────────────────────────────────────────────
    static let keyMessage = "message"
    static let keyTitle = "title"
    static let keyButton1Text = "button1Text"
    static let keyButton2Text = "button2Text"
    static let keyResourceName = "resourceName"
    static let keyWidth = "width"
    static let keyHeight = "height"
    static let keyOffsetX = "offsetX"
    static let keyOffsetY = "offsetY"
    static let keyTotalFrames = "totalFrames"

    // ── Study channel contract v2 ─────────────────────────────────
    static let keyReminderId = "reminderId"
    static let keyVisibilityMs = "visibilityMs"
    static let keyTimeoutMs = "timeoutMs"
    static let keyQuestion = "question"
    static let keyAction = "action"
}
