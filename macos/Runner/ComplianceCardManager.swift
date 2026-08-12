import Cocoa
import SwiftUI

/// The uniform compliance card (plan §5.4): a small panel at the top-right
/// corner of the screen with a question and two outcome buttons. Position,
/// size, styling, and behavior are identical for every reminder, placement,
/// style, day, and participant — it is the constant measurement instrument
/// of the study, so nothing about it is parameterized by condition.
class ComplianceCardManager {
    private static var cardWindow: NSPanel?
    private static var timeoutTimer: Timer?

    /// Gap between the card and the top/right edges of the screen (points).
    /// Increase to push the card lower / more inward.
    static let edgeMargin: CGFloat = 28

    static func show(
        question: String,
        button1Text: String,
        button2Text: String,
        timeoutMs: Int,
        onAction: @escaping (String) -> Void,
        onTimeout: @escaping () -> Void
    ) {
        dismiss()

        let contentView = ComplianceCardView(
            question: question,
            button1Text: button1Text,
            button2Text: button2Text,
            onAction: { action in
                onAction(action)
                dismiss()
            }
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
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.canHide = false
        panel.contentView = hostingView

        // Top-right corner of the screen the app's window is on (falls back
        // to the main screen). Anchoring to the app's window screen keeps the
        // card on the display the participant is actually looking at.
        let screen = NSApp.mainWindow?.screen ?? NSScreen.main
        if let screen {
            let x = screen.frame.maxX - idealSize.width - edgeMargin
            let y = screen.frame.maxY - idealSize.height - edgeMargin
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.makeKeyAndOrderFront(nil)
        self.cardWindow = panel

        let seconds = max(1.0, Double(timeoutMs) / 1000.0)
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            dismiss()
            onTimeout()
        }
    }

    static func dismiss() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        cardWindow?.close()
        cardWindow = nil
    }
}
