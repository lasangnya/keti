//
//  IslandManager.swift
//  Runner
//
//  Created by Lasan Gonsal Korala on 08.07.26.
//
import Cocoa
import SwiftUI

class IslandManager {
    static var window: NSPanel?

    static func show(message: String, resourceName: String, width: Double, height: Double, totalFrames: Int, onDone: @escaping () -> Void) {
        window?.close()

        let contentView = IslandView(message: message, resourceName: resourceName, totalFrames: totalFrames) {
            window?.close()
            window = nil
            onDone()
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)),
            styleMask: [.borderless, .nonactivatingPanel], // Borderless & doesn't steal focus
            backing: .buffered,
            defer: false
        )

        // Configure the Panel for "Always on Top"
        panel.level = NSWindow.Level(Int(NSWindow.Level.mainMenu.rawValue) + 1)
        panel.backgroundColor = NSColor.clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.canHide = false // Remains visible when app is minimized

        // Host the SwiftUI view
        panel.contentView = NSHostingView(rootView: contentView)

        // Position at the top center of the screen
        if let screen = NSScreen.main {
            let x = (screen.frame.width - CGFloat(width)) / 2
            let y = screen.frame.height - CGFloat(height) + 5
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.makeKeyAndOrderFront(nil)
        self.window = panel
    }
}
