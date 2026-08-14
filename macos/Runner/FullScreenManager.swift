import Cocoa

/// Owns the app's manual full-screen mode and the temporary menu-bar reveal
/// during reminders.
///
/// The app does NOT use AppKit's system full screen (which owns the menu bar
/// and cannot reveal it on demand). Instead the window zooms to the full
/// screen and this manager hides the menu bar (and dock) for the duration.
/// Because the window never enters system full screen, `setMenuBarVisible`
/// works reliably, so a reminder can temporarily reveal the bar.
enum FullScreenManager {
    private(set) static var isFullScreen = false
    private static var menuBarRevealed = false

    /// Called when the app's manual full-screen mode starts or ends.
    static func setFullScreen(_ fullScreen: Bool) {
        isFullScreen = fullScreen
        menuBarRevealed = false
        if fullScreen {
            if NSMenu.menuBarVisible() { NSMenu.setMenuBarVisible(false) }
            NSApp.presentationOptions.insert(.autoHideDock)
        } else {
            if !NSMenu.menuBarVisible() { NSMenu.setMenuBarVisible(true) }
            NSApp.presentationOptions.remove(.autoHideDock)
        }
    }

    /// Reveals the menu bar while a reminder is on screen, but only in full
    /// screen — windowed mode keeps it visible anyway. Idempotent, so
    /// overlapping reminder surfaces cannot double-toggle it.
    static func revealMenuBarForReminder() {
        guard isFullScreen, !menuBarRevealed else { return }
        NSMenu.setMenuBarVisible(true)
        menuBarRevealed = true
    }

    /// Restores the hidden menu bar once the reminder is gone.
    static func restoreMenuBar() {
        guard menuBarRevealed else { return }
        NSMenu.setMenuBarVisible(false)
        menuBarRevealed = false
    }
}
