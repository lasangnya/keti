import Cocoa
import SwiftUI

class ComplianceCardManager {
    private static var statusItem: NSStatusItem?
    private static var cardWindow: NSPanel?
    private static var autoDismissTimer: Timer?
    
    static func setup() {
        if statusItem != nil { return }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.isHidden = true
    }
    
    static func show(
        title: String,
        button1Text: String,
        button2Text: String,
        onButtonClicked: @escaping (String) -> Void
    ) {
        if statusItem?.button == nil { setup() }
        
        dismiss()
        
        guard let button = statusItem?.button else { return }
        button.isHidden = false
        // Temporary placeholder image for the tray anchor
        button.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
        
        let contentView = ComplianceCardView(
            title: title,
            button1Text: button1Text,
            button2Text: button2Text,
            onAction: { btnLabel in
                onButtonClicked(btnLabel)
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
        
        panel.level = .mainMenu
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.contentView = hostingView
        
        if let windowFrame = button.window?.frame {
            let x = windowFrame.origin.x + (windowFrame.width / 2) - (idealSize.width / 2)
            let y = windowFrame.origin.y - idealSize.height - 8
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        panel.makeKeyAndOrderFront(nil)
        self.cardWindow = panel
        
        // Auto-dismiss after 5 seconds
        autoDismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            dismiss()
        }
    }
    
    static func dismiss() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
        cardWindow?.close()
        cardWindow = nil
        statusItem?.button?.isHidden = true
    }
}
