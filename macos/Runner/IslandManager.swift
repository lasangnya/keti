import Cocoa
import SwiftUI

class IslandManager {
    static var window: NSPanel?
    private static var windowTimer: Timer?
    private static var currentOnHidden: (() -> Void)?

    static func show(message: String, resourceName: String, width: Double, height: Double, totalFrames: Int, visibilityMs: Int, onShown: @escaping () -> Void, onHidden: @escaping () -> Void) {
        // If an island is already showing, dismiss it first (and trigger its onHidden).
        dismiss()

        let contentView = IslandView(message: message, resourceName: resourceName, totalFrames: totalFrames, visibilityMs: visibilityMs)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = NSWindow.Level(Int(NSWindow.Level.mainMenu.rawValue) + 1)
        panel.backgroundColor = NSColor.clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.canHide = false

        panel.contentView = NSHostingView(rootView: contentView)

        if let screen = NSScreen.main {
            let x = (screen.frame.width - CGFloat(width)) / 2
            let y = screen.frame.height - CGFloat(height) + 5
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.makeKeyAndOrderFront(nil)
        self.window = panel
        self.currentOnHidden = onHidden

        onShown()

        let seconds = max(0.1, Double(visibilityMs) / 1000.0)
        windowTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            dismiss()
        }
    }

    static func dismiss() {
        windowTimer?.invalidate()
        windowTimer = nil
        
        window?.close()
        window = nil
        
        // Ensure the sequence in Flutter finishes if we clobbered it.
        currentOnHidden?()
        currentOnHidden = nil
    }
}
