import Cocoa

/// Manages a persistent item in the macOS system tray (menu bar).
/// By initializing at app launch, it secures a position on the right side of the tray.
class TrayPillManager {
    private static var statusItem: NSStatusItem?
    private static let visibilityDuration: TimeInterval = 3.0

    /// Initializes the tray item and hides it. Call this at app launch.
    static func setup() {
        print("TrayPillManager: Setting up status item...")
        if statusItem != nil { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.isHidden = true
        statusItem?.autosaveName = "KetiTrayPill"

        if #available(macOS 12.0, *) {
            let color = NSColor(red: 79/255.0, green: 198/255.0, blue: 216/255.0, alpha: 1.0)
            let config = NSImage.SymbolConfiguration(paletteColors: [color])
            let image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "Reminder")
            statusItem?.button?.image = image?.withSymbolConfiguration(config)
        } else if #available(macOS 11.0, *) {
            let image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "Reminder")
            image?.isTemplate = true
            statusItem?.button?.image = image
        }
    }

    /// Makes the tray item visible for a short duration.
    static func show() {
        print("TrayPillManager: Request to show...")
        if statusItem?.button == nil { setup() }

        statusItem?.button?.isHidden = false
        statusItem?.button?.highlight(true)

        DispatchQueue.main.asyncAfter(deadline: .now() + visibilityDuration) {
            dismiss()
        }
    }

    /// Hides the tray item.
    static func dismiss() {
        print("TrayPillManager: Dismissing status item...")
        statusItem?.button?.isHidden = true
    }
}
