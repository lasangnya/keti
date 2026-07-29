import Cocoa
import SwiftUI

/// Shows an animated PNG sequence next to the mouse cursor.
/// The animation follows the cursor, holds its final frame once the sequence
/// ends, and stays visible until the visibility window elapses.
class CursorPillManager {
    private static var window: NSPanel?
    private static var trackingTimer: Timer?
    private static var windowTimer: Timer?

    private static var currentWidth: Double = 150
    private static var currentHeight: Double = 150
    private static var currentOffsetX: Double = 0
    private static var currentOffsetY: Double = 0

    static func show(resourceName: String, width: Double, height: Double, offsetX: Double, offsetY: Double, totalFrames: Int, visibilityMs: Int, onShown: @escaping () -> Void, onHidden: @escaping () -> Void) {
        dismiss()

        currentWidth = width
        currentHeight = height
        currentOffsetX = offsetX
        currentOffsetY = offsetY

        let pillSize = NSSize(width: width, height: height)

        let contentView = CursorPillView(resourceName: resourceName, frameCount: totalFrames)

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

        positionAtCursor()

        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard window != nil else { return }
            positionAtCursor()
        }

        onShown()

        let seconds = max(0.1, Double(visibilityMs) / 1000.0)
        windowTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            dismiss()
            onHidden()
        }
    }

    static func dismiss() {
        trackingTimer?.invalidate()
        trackingTimer = nil
        windowTimer?.invalidate()
        windowTimer = nil

        window?.close()
        window = nil
    }

    private static func positionAtCursor() {
        guard let panel = window else { return }
        let mouse = NSEvent.mouseLocation
        panel.setFrameOrigin(NSPoint(x: mouse.x + currentOffsetX, y: mouse.y + currentOffsetY))
    }
}

// MARK: - Animated SwiftUI View

struct CursorPillView: View {
    let resourceName : String
    let frameCount: Int

    @State private var currentFrame = 0
    @State private var isVisible = false

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
            .scaleEffect(isVisible ? 1.0 : 0.5)
            .opacity(isVisible ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isVisible = true
                }
            }
    }
}
