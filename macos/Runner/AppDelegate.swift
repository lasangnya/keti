import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    /// Set from Flutter via the app.keti/session_lifecycle channel while a
    /// study session is active. Keeps the process alive when the main
    /// window closes and suppresses App Nap (plan §6.5).
    private var sessionActive = false
    private var sessionActivity: NSObjectProtocol?

    override func applicationDidFinishLaunching(_ notification: Notification) {
        // Calling setup here ensures we are the first 3rd-party app to request a slot.
        TrayPillManager.setup()
        super.applicationDidFinishLaunching(notification)

        // Directly-spawned instances (the researcher window) are never
        // activated by LaunchServices. An inactive app's window is reported
        // as occluded, so the Flutter engine pauses the rasterizer and the
        // surface stays black. Activating synchronously here is too early to
        // win the launch race — defer to the next runloop turn (the pattern
        // Ghostty uses for CLI-spawned instances) and order the window front.
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            NSApp.unhide(nil)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
            NSApp.arrangeInFront(nil)
        }
        // Retry once the window server has settled — the first activation
        // attempt during a directly-spawned launch can be dropped.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.arrangeInFront(nil)
        }

        installViewMenu()
    }

    /// Re-adds the standard "Toggle Full Screen" (⌃⌘F) shortcut, which the
    /// system normally provides for full-screen-capable windows. The app's
    /// manual full screen is not system full screen, so the shortcut is wired
    /// to the same zoom action the green button uses.
    private func installViewMenu() {
        guard let mainMenu = NSApp.mainMenu else { return }
        let viewItem = NSMenuItem(title: "View", action: nil, keyEquivalent: "")
        let viewMenu = NSMenu(title: "View")
        let toggle = NSMenuItem(
            title: "Toggle Full Screen",
            action: #selector(toggleManualFullScreen(_:)),
            keyEquivalent: "f"
        )
        toggle.keyEquivalentModifierMask = [.command, .control]
        toggle.target = self
        viewMenu.addItem(toggle)
        viewItem.submenu = viewMenu
        mainMenu.addItem(viewItem)
    }

    @objc private func toggleManualFullScreen(_ sender: Any?) {
        (NSApp.keyWindow ?? NSApp.mainWindow)?.performZoom(sender)
    }

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // During an active study session the scheduler must keep running
        // even if the participant closes the window.
        return !sessionActive
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationWillTerminate(_ notification: Notification) {
        if let activity = sessionActivity {
            ProcessInfo.processInfo.endActivity(activity)
            sessionActivity = nil
        }
        // Never leave the system menu bar hidden after the app quits.
        if !NSMenu.menuBarVisible() {
            NSMenu.setMenuBarVisible(true)
        }
        NSApp.presentationOptions.remove(.autoHideDock)
    }

    func setSessionActive(_ active: Bool) {
        sessionActive = active
        if active {
            if sessionActivity == nil {
                sessionActivity = ProcessInfo.processInfo.beginActivity(
                    options: .userInitiated,
                    reason: "keti study session in progress"
                )
            }
        } else if let activity = sessionActivity {
            ProcessInfo.processInfo.endActivity(activity)
            sessionActivity = nil
        }
    }
}
