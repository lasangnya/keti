import Cocoa
import SwiftUI

/// Manages a persistent item in the macOS system tray and a "dropped" card.
class TrayPillManager {
    private static var statusItem: NSStatusItem?
    private static var cardWindow: NSPanel?
    private static var animationTimer: Timer?

    /// Initializes the tray item and hides it. Call this at app launch.
    static func setup() {
        if statusItem != nil { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.isHidden = true
        statusItem?.autosaveName = "KetiTrayPill"
    }

    /// Makes the tray item visible and "drops" a small card underneath.
    static func show(message: String, resourceName: String, width: Double, height: Double, totalFrames: Int, onDone: @escaping () -> Void) {
        if statusItem?.button == nil { setup() }
        
        dismiss() // Clear previous instance
        
        guard let button = statusItem?.button else { return }
        button.isHidden = false
        button.highlight(true)

        // 1. Play PNG sequence animation in the tray
        var currentFrame = 0
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { _ in
            let frameName = String(format: "\(resourceName)_%05d", currentFrame)
            if let image = NSImage(named: frameName) {
                // Use dynamic dimensions passed from Flutter
                image.size = NSSize(width: CGFloat(width), height: CGFloat(height))
                image.isTemplate = false // Keep original colors as requested
                button.image = image
            }
            if currentFrame < totalFrames - 1 {
                currentFrame += 1
            } else {
                // Sequence finished, dismiss everything
                dismiss()
                onDone()
            }
        }

        // 2. Show the "Dropped" Card with the same resource
        showCard(message: message, resourceName: resourceName, totalFrames: totalFrames, anchoredTo: button)
    }

    private static func showCard(message: String, resourceName: String, totalFrames: Int, anchoredTo button: NSStatusBarButton) {
        let contentView = TrayCardView(message: message, resourceName: resourceName, totalFrames: totalFrames)
        let hostingView = NSHostingView(rootView: contentView)
        
        // Let SwiftUI calculate the ideal size for the text
        let idealSize = hostingView.fittingSize
        
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: idealSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = NSWindow.Level(Int(NSWindow.Level.mainMenu.rawValue) + 1)
        panel.backgroundColor = NSColor.clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.contentView = hostingView
        
        // Position exactly under the tray button
        if let windowFrame = button.window?.frame {
            let x = windowFrame.origin.x + (windowFrame.width / 2) - (idealSize.width / 2)
            let y = windowFrame.origin.y - idealSize.height - 4 // 4px gap
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        panel.makeKeyAndOrderFront(nil)
        self.cardWindow = panel
    }

    /// Hides the tray item and the card.
    static func dismiss() {
        animationTimer?.invalidate()
        animationTimer = nil
        
        statusItem?.button?.isHidden = true
        
        cardWindow?.close()
        cardWindow = nil
    }
}
