import Cocoa
import SwiftUI

/// Shows an animated PNG sequence next to the mouse cursor.
/// The animation follows the cursor and auto-hides after 4 seconds.
class CursorPillManager {
    private static var window: NSPanel?
    private static var trackingTimer: Timer?
    
    private static var currentWidth: Double = 150
    private static var currentHeight: Double = 150
    private static var currentOffsetX: Double = 0
    private static var currentOffsetY: Double = 0

    private static let visibilityDuration: TimeInterval = 4.0

    static func show(resourceName: String, width: Double, height: Double, offsetX: Double, offsetY: Double) {
        dismiss()
        
        currentWidth = width
        currentHeight = height
        currentOffsetX = offsetX
        currentOffsetY = offsetY

        let pillSize = NSSize(width: width, height: height)
        let contentView = CursorPillView(resourceName: resourceName, frameCount: 120)
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
        // Apply dynamic offset
        panel.setFrameOrigin(NSPoint(x: mouse.x + currentOffsetX, y: mouse.y + currentOffsetY))
    }
}

// MARK: - Animated SwiftUI View

struct CursorPillView: View {
    let resourceName : String
    let frameCount: Int
    @State private var currentFrame = 0

    // ~30 FPS (4 seconds for 120 frames)
    let timer = Timer.publish(every: 0.033, on: .main, in: .common).autoconnect()

    var body: some View {
        let frameName = String(format: "\(resourceName)_%05d", currentFrame)

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
