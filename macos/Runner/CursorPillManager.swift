import Cocoa
import SwiftUI

/// Shows an animated PNG sequence next to the mouse cursor.
/// The animation follows the cursor, holds its final frame once the sequence
/// ends, and stays visible until the visibility window elapses.
class CursorPillManager {
    private static var window: NSPanel?
    private static var trackingTimer: Timer?
    private static var currentOnHidden: (() -> Void)?
    private static var dismissWorkItem: DispatchWorkItem?

    private static var currentWidth: Double = 150
    private static var currentHeight: Double = 150
    private static var currentOffsetX: Double = 0
    private static var currentOffsetY: Double = 0

    static func show(resourceName: String, width: Double, height: Double, offsetX: Double, offsetY: Double, totalFrames: Int, visibilityMs: Int, onShown: @escaping () -> Void, onHidden: @escaping () -> Void) {
        let t0 = CFAbsoluteTimeGetCurrent()
        print("[CursorPillManager] show() called. visibilityMs=\(visibilityMs) totalFrames=\(totalFrames) resource=\(resourceName)")

        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        closeInstantly()

        FullScreenManager.revealMenuBarForReminder()

        currentWidth = width
        currentHeight = height
        currentOffsetX = offsetX
        currentOffsetY = offsetY

        let pillSize = NSSize(width: width, height: height)

        let contentView = CursorPillView(
            resourceName: resourceName,
            frameCount: totalFrames,
            visibilityMs: visibilityMs,
            onAnimationDone: {
                print("[CursorPillManager] 🔔 onAnimationDone callback fired from CursorPillView")
                closeInstantly()
            }
        )

        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame.size = pillSize

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: pillSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = NSWindow.Level(Int(NSWindow.Level.mainMenu.rawValue) + 1)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.canHide = false
        panel.ignoresMouseEvents = true

        panel.contentView = hostingView
        panel.makeKeyAndOrderFront(nil)
        window = panel
        currentOnHidden = onHidden

        positionAtCursor()

        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard window != nil else { return }
            positionAtCursor()
        }

        print("[CursorPillManager] Window ordered front. Calling onShown(). t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
        onShown()

        // Safety-net timer: the view schedules its own exit animation and
        // calls onAnimationDone when settled. This fires slightly later to
        // guarantee cleanup even if the view's timer is missed.
        let workItem = DispatchWorkItem {
            print("[CursorPillManager] 🛟 SAFETY-NET timer fired — closing window. t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
            closeInstantly()
        }
        dismissWorkItem = workItem
        let holdSeconds = max(0.1, Double(visibilityMs) / 1000.0)
        let bufferSeconds: Double = 0.6 // leave room for the 0.5 s spring exit
        let totalDelay = holdSeconds + bufferSeconds
        print("[CursorPillManager] Safety-net timer scheduled in \(String(format: "%.3f", totalDelay))s (hold=\(String(format: "%.3f", holdSeconds))s + buffer=\(bufferSeconds)s)")
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay,
                                      execute: workItem)
        print("[CursorPillManager] show() complete. t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
    }

    private static func closeInstantly() {
        let hadWindow = window != nil
        print("[CursorPillManager] 💥 closeInstantly() called. hadWindow=\(hadWindow)")
        trackingTimer?.invalidate()
        trackingTimer = nil

        window?.orderOut(nil)
        window?.close()
        window = nil

        FullScreenManager.restoreMenuBar()

        currentOnHidden?()
        currentOnHidden = nil
    }

    static func dismiss() {
        print("[CursorPillManager] dismiss() called (external/manual)")
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        closeInstantly()
    }

    private static func positionAtCursor() {
        guard let panel = window else { return }
        let mouse = NSEvent.mouseLocation
        var x = mouse.x + currentOffsetX
        var y = mouse.y + currentOffsetY
        // Clamp into the visible frame so the pill never clips at the top
        // edge in full screen (or anywhere else).
        if let visible = NSScreen.main?.visibleFrame {
            let maxX = max(visible.minX, visible.maxX - currentWidth)
            let maxY = max(visible.minY, visible.maxY - currentHeight)
            x = min(max(x, visible.minX), maxX)
            y = min(max(y, visible.minY), maxY)
        }
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

// MARK: - Animated SwiftUI View

struct CursorPillView: View {
    let resourceName : String
    let frameCount: Int
    let visibilityMs: Int
    let onAnimationDone: () -> Void

    @State private var currentFrame = 0
    @State private var isVisible = false
    @State private var hasFinished = false

    let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()

    var body: some View {
        let frameName = String(format: "\(resourceName)_%05d", currentFrame)

        Image(frameName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .onReceive(timer) { _ in
                if currentFrame < frameCount - 1 {
                    currentFrame += 1
                } else if !hasFinished {
                    let t0 = CFAbsoluteTimeGetCurrent()
                    print("[CursorPillView] 🎞️ Last frame reached — starting out-animation. frameCount=\(frameCount)")
                    hasFinished = true
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        isVisible = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("[CursorPillView] ✅ onAnimationDone() called. t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
                        onAnimationDone()
                    }
                }
            }
            .scaleEffect(isVisible ? 1.0 : 0.5)
            .opacity(isVisible ? 1.0 : 0.0)
            .onAppear {
                let t0 = CFAbsoluteTimeGetCurrent()
                print("[CursorPillView] onAppear fired. frameCount=\(frameCount)")

                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isVisible = true
                }
                print("[CursorPillView] In-animation started (isVisible -> true). t=\(String(format: "%.3f", CFAbsoluteTimeGetCurrent() - t0))s")
            }
            .onDisappear {
                print("[CursorPillView] 👻 onDisappear fired")
            }
    }
}
