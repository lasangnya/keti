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

        // Directly-spawned instances (researcher window) arrive inactive,
        // leaving the Flutter surface black until activated.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
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
