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

        applyIcon()
    }

    private static func applyIcon() {
        // First check for macOS 11.0 (SF Symbols support)
        guard #available(macOS 11.0, *) else { return }

        let image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "Reminder")

        // Then try for macOS 12.0 (Color support)
        if #available(macOS 12.0, *) {
            let blue = NSColor(red: 0.31, green: 0.78, blue: 0.85, alpha: 1.0)
            let config = NSImage.SymbolConfiguration(paletteColors: [blue])
            statusItem?.button?.image = image?.withSymbolConfiguration(config)
        } else {
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
        statusItem?.button?.isHidden = true
    }
}
