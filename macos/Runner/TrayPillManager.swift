import Cocoa

/// Manages a persistent item in the macOS system tray (menu bar).
/// By initializing at app launch, it secures a position on the right side of the tray.
class TrayPillManager {
    private static var statusItem: NSStatusItem?
    private static let visibilityDuration: TimeInterval = 4.0
    private static var animationTimer: Timer?

    /// Initializes the tray item and hides it. Call this at app launch.
    static func setup() {
        print("TrayPillManager: Setting up status item...")
        if statusItem != nil { return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.isHidden = true
        statusItem?.autosaveName = "KetiTrayPill"
    }

    /// Makes the tray item visible and plays an animation sequence.
    static func show(resourceName: String) {
        print("TrayPillManager: Request to show \(resourceName)...")
        if statusItem?.button == nil { setup() }
        
        stopAnimation()
        
        let button = statusItem?.button
        button?.isHidden = false
        button?.highlight(true)

        // Start PNG sequence animation
        var currentFrame = 0
        let totalFrames = 120
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { _ in
            let frameName = String(format: "\(resourceName)_%05d", currentFrame)
            if let image = NSImage(named: frameName) {
                // Ensure it's treated as a template or keep original colors based on design
                // For character style, original colors might be better.
                button?.image = image
            }
            
            if currentFrame < totalFrames - 1 {
                currentFrame += 1
            } else {
                // Loop or stop is handled by the auto-dismiss timer
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + visibilityDuration) {
            dismiss()
        }
    }

    /// Hides the tray item.
    static func dismiss() {
        print("TrayPillManager: Dismissing status item...")
        stopAnimation()
        statusItem?.button?.isHidden = true
    }
    
    private static func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}
