import Cocoa
import SwiftUI

/// Manages a persistent item in the macOS system tray and a "dropped" card.
/// The tray animation plays once and holds its final frame; tray item and
/// card stay visible until the visibility window elapses.
class TrayPillManager {
    private static var statusItem: NSStatusItem?
    private static var cardWindow: NSPanel?
    private static var animationTimer: Timer?
    private static var currentOnHidden: (() -> Void)?
    private static var dismissWorkItem: DispatchWorkItem?

    /// Initializes the tray item and hides it. Call this at app launch.
    static func setup() {
        if statusItem != nil { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.isHidden = true
        statusItem?.autosaveName = "KetiTrayPill"
    }

    /// Makes the tray item visible and "drops" the message card underneath.
    static func show(message: String, resourceName: String, width: Double, height: Double, totalFrames: Int, visibilityMs: Int, onShown: @escaping () -> Void, onHidden: @escaping () -> Void) {
        let t0 = CFAbsoluteTimeGetCurrent()
        print("[TrayPillManager] show() called. visibilityMs=\(visibilityMs) totalFrames=\(totalFrames) resource=\(resourceName)")

        if statusItem?.button == nil { setup() }

        FullScreenManager.revealMenuBarForReminder()

        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        closeInstantly()

        guard let button = statusItem?.button else {
            print("[TrayPillManager] ❌ No statusItem button — aborting")
            return
        }
        button.isHidden = false
        button.highlight(true)

        // 1. Play PNG sequence animation once in the tray, then hold the
        //    final frame for the rest of the visibility window.
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

        // 2. Show the "Dropped" Card — the card handles its own exit animation.
        showCard(
            resourceName: resourceName,
            totalFrames: totalFrames,
            visibilityMs: visibilityMs,
            anchoredTo: button,
            onAnimationDone: {
                print("[TrayPillManager] 🔔 onAnimationDone callback fired from TrayCardView")
                closeInstantly()
            }
        )

        self.currentOnHidden = onHidden
        print("[TrayPillManager] Card shown. Calling onShown(). t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
        onShown()

        // Safety-net timer: the card schedules its own exit animation and
        // calls onAnimationDone when settled. This fires slightly later to
        // guarantee cleanup even if the card's timer is missed.
        let workItem = DispatchWorkItem {
            print("[TrayPillManager] 🛟 SAFETY-NET timer fired — closing window. t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
            closeInstantly()
        }
        dismissWorkItem = workItem
        let holdSeconds = max(0.1, Double(visibilityMs) / 1000.0)
        let bufferSeconds: Double = 0.6 // leave room for the 0.5 s spring exit
        let totalDelay = holdSeconds + bufferSeconds
        print("[TrayPillManager] Safety-net timer scheduled in \(String(format: "%.3f", totalDelay))s (hold=\(String(format: "%.3f", holdSeconds))s + buffer=\(bufferSeconds)s)")
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay,
                                      execute: workItem)
        print("[TrayPillManager] show() complete. t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
    }

    private static func showCard(resourceName: String, totalFrames: Int, visibilityMs: Int, anchoredTo button: NSStatusBarButton, onAnimationDone: @escaping () -> Void) {
        let contentView = TrayCardView(
            resourceName: resourceName,
            totalFrames: totalFrames,
            visibilityMs: visibilityMs,
            onAnimationDone: onAnimationDone
        )
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

        // When the menu bar was just revealed, its geometry needs a runloop
        // turn to settle; position then so the card drops below the bar.
        let position = {
            if let windowFrame = button.window?.frame {
                let x = windowFrame.origin.x + (windowFrame.width / 2) - (idealSize.width / 2)
                let y = self.clampToVisibleFrame(windowFrame.origin.y - idealSize.height - 4,
                                                 height: idealSize.height)
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            } else if let screen = NSScreen.main {
                // No status-item window (e.g. full screen with a hidden status
                // bar): anchor below the visible top of the screen instead.
                let visible = screen.visibleFrame
                panel.setFrameOrigin(NSPoint(
                    x: visible.midX - idealSize.width / 2,
                    y: visible.maxY - idealSize.height - 4
                ))
            }
        }
        if FullScreenManager.isFullScreen {
            DispatchQueue.main.async { position() }
        } else {
            position()
        }

        panel.makeKeyAndOrderFront(nil)
        self.cardWindow = panel
    }

    /// Clamps a Y position so the card stays fully inside the visible frame
    /// (menu bar / full-screen top edge included).
    private static func clampToVisibleFrame(_ y: CGFloat, height: CGFloat) -> CGFloat {
        guard let visible = NSScreen.main?.visibleFrame else { return y }
        let minY = visible.minY
        let maxY = max(minY, visible.maxY - height)
        return min(max(y, minY), maxY)
    }

    /// Purges the window and state instantly (no animation — the card's own
    /// exit animation should have completed before this is called).
    private static func closeInstantly() {
        let hadCard = cardWindow != nil
        print("[TrayPillManager] 💥 closeInstantly() called. hadCard=\(hadCard)")
        animationTimer?.invalidate()
        animationTimer = nil

        statusItem?.button?.isHidden = true

        cardWindow?.orderOut(nil)
        cardWindow?.close()
        cardWindow = nil

        FullScreenManager.restoreMenuBar()

        currentOnHidden?()
        currentOnHidden = nil
    }

    static func dismiss() {
        print("[TrayPillManager] dismiss() called (external/manual)")
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        closeInstantly()
    }
}
