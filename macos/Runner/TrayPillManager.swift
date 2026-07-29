import Cocoa
import SwiftUI

/// Manages a persistent item in the macOS system tray and a "dropped" card.
/// The tray animation plays once and holds its final frame; tray item and
/// card stay visible until the visibility window elapses.
class TrayPillManager {
    private static var statusItem: NSStatusItem?
    private static var cardWindow: NSPanel?
    private static var animationTimer: Timer?
    private static var windowTimer: Timer?
    private static var currentOnHidden: (() -> Void)?

    /// Initializes the tray item and hides it. Call this at app launch.
    static func setup() {
        if statusItem != nil { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.isHidden = true
        statusItem?.autosaveName = "KetiTrayPill"
    }

    /// Makes the tray item visible and "drops" the message card underneath.
    static func show(message: String, resourceName: String, width: Double, height: Double, totalFrames: Int, visibilityMs: Int, onShown: @escaping () -> Void, onHidden: @escaping () -> Void) {
        if statusItem?.button == nil { setup() }

        dismiss()

        guard let button = statusItem?.button else { return }
        button.isHidden = false
        button.highlight(true)

        // 1. Play PNG sequence animation once in the tray, then hold the
        // final frame for the rest of the window.
        var currentFrame = 0

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { timer in
            let frameName = String(format: "\(resourceName)_%05d", currentFrame)
            if let image = NSImage(named: frameName) {
                image.size = NSSize(width: CGFloat(width), height: CGFloat(height))
                image.isTemplate = false
                button.image = image
            }
            if currentFrame < totalFrames - 1 {
                currentFrame += 1
            } else {
                timer.invalidate()
                animationTimer = nil
            }
        }

        // 2. Show the "Dropped" Card with the message text.
        showCard(message: message, resourceName: resourceName, totalFrames: totalFrames, visibilityMs: visibilityMs, anchoredTo: button)

        self.currentOnHidden = onHidden
        onShown()

        let seconds = max(0.1, Double(visibilityMs) / 1000.0)
        windowTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            dismiss()
        }
    }

    private static func showCard(message: String, resourceName: String, totalFrames: Int, visibilityMs: Int, anchoredTo button: NSStatusBarButton) {
        let contentView = TrayCardView(message: message, resourceName: resourceName, totalFrames: totalFrames, visibilityMs: visibilityMs)
        let hostingView = NSHostingView(rootView: contentView)

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

        if let windowFrame = button.window?.frame {
            let x = windowFrame.origin.x + (windowFrame.width / 2) - (idealSize.width / 2)
            let y = windowFrame.origin.y - idealSize.height - 4
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.makeKeyAndOrderFront(nil)
        self.cardWindow = panel
    }

    /// Hides the tray item and the card.
    static func dismiss() {
        animationTimer?.invalidate()
        animationTimer = nil
        windowTimer?.invalidate()
        windowTimer = nil

        statusItem?.button?.isHidden = true

        cardWindow?.close()
        cardWindow = nil
        
        currentOnHidden?()
        currentOnHidden = nil
    }
}
