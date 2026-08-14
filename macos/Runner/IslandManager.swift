import Cocoa
import SwiftUI

class IslandManager {
    private static var window: NSPanel?
    private static var currentOnHidden: (() -> Void)?
    private static var dismissWorkItem: DispatchWorkItem?

    static func show(message: String, resourceName: String, width: Double, height: Double, totalFrames: Int, visibilityMs: Int, onShown: @escaping () -> Void, onHidden: @escaping () -> Void) {
        let t0 = CFAbsoluteTimeGetCurrent()
        print("[IslandManager] show() called. visibilityMs=\(visibilityMs) totalFrames=\(totalFrames) resource=\(resourceName)")

        // 1. Force-kill any existing window instantly (no animation for clobbered).
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        closeInstantly()

        // In full screen the menu bar is hidden; reveal it for the reminder
        // window so the panel does not sit in the invisible top strip.
        FullScreenManager.revealMenuBarForReminder()

        let contentView = IslandView(
            message: message,
            resourceName: resourceName,
            totalFrames: totalFrames,
            visibilityMs: visibilityMs,
            onAnimationDone: {
                print("[IslandManager] 🔔 onAnimationDone callback fired from IslandView")
                closeInstantly()
            }
        )

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

        // When the menu bar was just revealed, visibleFrame needs a runloop
        // turn to settle; position then so the panel sits below the bar.
        let position = {
            if let screen = NSScreen.main {
                // Anchor to the VISIBLE frame: it excludes the menu bar (and,
                // in full screen, tracks the auto-hidden bar), so the panel
                // never lands in a strip that is off-screen or hidden.
                let visible = screen.visibleFrame
                let x = visible.midX - CGFloat(width) / 2
                let y = visible.maxY - CGFloat(height) + 5
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            }
        }
        if FullScreenManager.isFullScreen {
            DispatchQueue.main.async { position() }
        } else {
            position()
        }

        panel.makeKeyAndOrderFront(nil)
        self.window = panel
        self.currentOnHidden = onHidden

        print("[IslandManager] Window ordered front. Calling onShown(). t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
        onShown()

        // 2. Safety-net timer: the view schedules its own exit animation and
        //    calls onAnimationDone when settled. This fires slightly later to
        //    guarantee cleanup even if the view's timer is missed.
        let workItem = DispatchWorkItem {
            print("[IslandManager] 🛟 SAFETY-NET timer fired — closing window. t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
            closeInstantly()
        }
        dismissWorkItem = workItem
        let holdSeconds = max(0.1, Double(visibilityMs) / 1000.0)
        let bufferSeconds: Double = 0.6 // leave room for the 0.5 s spring exit
        let totalDelay = holdSeconds + bufferSeconds
        print("[IslandManager] Safety-net timer scheduled in \(String(format: "%.3f", totalDelay))s (hold=\(String(format: "%.3f", holdSeconds))s + buffer=\(bufferSeconds)s)")
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay,
                                      execute: workItem)
        print("[IslandManager] show() complete. t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
    }

    /// Purges the window and state instantly.
    private static func closeInstantly() {
        let hadWindow = window != nil
        print("[IslandManager] 💥 closeInstantly() called. hadWindow=\(hadWindow)")
        window?.orderOut(nil)
        window?.close()
        window = nil

        FullScreenManager.restoreMenuBar()

        currentOnHidden?()
        currentOnHidden = nil
    }

    static func dismiss() {
        print("[IslandManager] dismiss() called (external/manual)")
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        closeInstantly()
    }
}
