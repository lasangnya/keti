import Cocoa

/// Manages a persistent item in the macOS system tray (menu bar).
/// By initializing at app launch, it secures a position on the right side of the tray.
class TrayPillManager {
    private static var statusItem: NSStatusItem?
    private static let visibilityDuration: TimeInterval = 3.0

    /// Initializes the tray item and hides it. Call this at app launch.
    static func setup() {
        if statusItem == nil {
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            statusItem?.button?.isHidden = true // Keep hidden until a reminder occurs

            statusItem?.autosaveName = "KetiTrayPill"

            if #available(macOS 11.0, *) {
                let image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "Reminder")
                image?.isTemplate = true
                statusItem?.button?.image = image
            }
        } else {
            print("TrayPillManager: Status item already exists.")
        }
    }

    /// Makes the tray item visible for a short duration.
    static func show() {
        print("TrayPillManager: Request to show...")
        guard let button = statusItem?.button else {
            // Fallback: if setup wasn't called or failed, try to setup now
            setup()
            show()
            return
        }

        // Unhide and highlight to grab attention
        button.isHidden = false
        button.highlight(true)

        // Automatically hide after the duration
        DispatchQueue.main.asyncAfter(deadline: .now() + visibilityDuration) {
            dismiss()
        }
    }

    /// Hides the tray item.
    static func dismiss() {
        statusItem?.button?.isHidden = true
    }
}
