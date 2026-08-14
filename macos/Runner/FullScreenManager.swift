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
            // The auto-hide option gives the system full-screen hover
            // behavior ("appears when the pointer nears the top edge") and
            // is what makes the bar showable at all while the window covers
            // the menu-bar strip.
            NSApp.presentationOptions.insert(.autoHideMenuBar)
            NSApp.presentationOptions.insert(.autoHideDock)
            if NSMenu.menuBarVisible() { NSMenu.setMenuBarVisible(false) }
        } else {
            NSApp.presentationOptions.remove(.autoHideMenuBar)
            NSApp.presentationOptions.remove(.autoHideDock)
            if !NSMenu.menuBarVisible() { NSMenu.setMenuBarVisible(true) }
        }
    }

    /// Reveals the menu bar while a reminder is on screen, but only in full
    /// screen — windowed mode keeps it visible anyway. Idempotent, so
    /// overlapping reminder surfaces cannot double-toggle it.
    static func revealMenuBarForReminder() {
        guard isFullScreen, !menuBarRevealed else { return }
        // Force-show for the reminder: dropping the auto-hide option makes
        // the bar stay up (the Ghostty/IINA pattern); setMenuBarVisible is
        // kept as a belt-and-suspenders for older macOS behavior.
        NSApp.presentationOptions.remove(.autoHideMenuBar)
        NSMenu.setMenuBarVisible(true)
        menuBarRevealed = true
        debugPrint("[FullScreenManager] menu bar revealed for reminder")
    }

    /// Restores the hidden menu bar once the reminder is gone.
    static func restoreMenuBar() {
        guard menuBarRevealed else { return }
        NSMenu.setMenuBarVisible(false)
        NSApp.presentationOptions.insert(.autoHideMenuBar)
        menuBarRevealed = false
        debugPrint("[FullScreenManager] menu bar restored")
    }
}
