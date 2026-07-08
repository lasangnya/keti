import Cocoa
import SwiftUI

/// Shows a horizontal orange pill next to the mouse cursor.
/// The pill follows the cursor via a high-frequency Timer and auto-hides after 3 seconds.
class CursorPillManager {
    private static var window: NSPanel?
    private static var trackingTimer: Timer?

    private static let pillSize = NSSize(width: 200, height: 44)
    private static let visibilityDuration: TimeInterval = 3.0

    static func show() {
        // Tear down any existing pill
        dismiss()

        let contentView = CursorPillView()
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame.size = pillSize

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: pillSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .mainMenu + 1  // same level as IslandManager — sits above everything
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.canHide = false
        panel.ignoresMouseEvents = true

        panel.contentView = hostingView
        panel.makeKeyAndOrderFront(nil)
        window = panel

        // Position at the current cursor immediately
        positionAtCursor()

        // Track cursor at ~60fps
        trackingTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard window != nil else {
                trackingTimer?.invalidate()
                trackingTimer = nil
                return
            }
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

    // MARK: - Private

    private static func positionAtCursor() {
        guard let panel = window else { return }
        let mouse = NSEvent.mouseLocation
        // Offset: pill appears to the right and slightly above the cursor
        panel.setFrameOrigin(NSPoint(x: mouse.x + 16, y: mouse.y + 16))
    }
}

// MARK: - SwiftUI View

struct CursorPillView: View {
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.orange)
                .frame(width: 10, height: 10)

            Text("💧 Time to drink water!")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(width: 200, height: 44)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.9))
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 3)
        )
    }
}
