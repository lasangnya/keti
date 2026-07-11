import Cocoa
import SwiftUI

/// Shows an animated PNG sequence next to the mouse cursor.
/// The animation follows the cursor and auto-hides after 4 seconds.
class CursorPillManager {
    private static var window: NSPanel?
    private static var trackingTimer: Timer?

    // 1. Adjust size to match
    private static let pillSize = NSSize(width: 86, height: 15)
    private static let visibilityDuration: TimeInterval = 4.0

    static func show() {
        dismiss()

        // 2. We have 120 frames (00000 to 00119)
        let contentView = CursorPillView(frameCount: 120)
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame.size = pillSize

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: pillSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .mainMenu + 1
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.canHide = false
        panel.ignoresMouseEvents = true

        panel.contentView = hostingView
        panel.makeKeyAndOrderFront(nil)
        window = panel

        positionAtCursor()

        // Track cursor at 60fps
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard window != nil else { return }
            positionAtCursor()
        }

        // Auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + visibilityDuration) {
            dismiss()
        }
    }

    static func dismiss() {
        trackingTimer?.invalidate()
        trackingTimer = nil

        window?.close()
        window = nil
    }

    private static func positionAtCursor() {
        guard let panel = window else { return }
        let mouse = NSEvent.mouseLocation
        // Center the animation on the tip of the cursor
        panel.setFrameOrigin(NSPoint(x: mouse.x - 10 , y: mouse.y - 30 ))
    }
}

// MARK: - Animated SwiftUI View

struct CursorPillView: View {
    let frameCount: Int
    @State private var currentFrame = 0

    // ~30 FPS (4 seconds for 120 frames)
    let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()

    var body: some View {
        let frameName = String(format: "ambient_cursor_pill_%05d", currentFrame)

        Image(frameName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .onReceive(timer) { _ in
                if currentFrame < frameCount - 1 {
                    currentFrame += 1
                }
            }
    }
}
