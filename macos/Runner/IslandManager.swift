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

    static func show(message: String, resourceName: String) {
        window?.close()

        let contentView = IslandView(message: message, resourceName: resourceName) {
            window?.close()
            window = nil
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 80),
            styleMask: [.borderless, .nonactivatingPanel], // Borderless & doesn't steal focus
            backing: .buffered,
            defer: false
        )

        // Configure the Panel for "Always on Top"
        panel.level = .mainMenu + 1 // Sits above almost everything
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.canHide = false // Remains visible when app is minimized

        // Host the SwiftUI view
        panel.contentView = NSHostingView(rootView: contentView)

        // Position at the top center of the screen
        if let screen = NSScreen.main {
            let x = (screen.frame.width - panel.frame.width) / 2
            let y = screen.frame.height - panel.frame.height - 50 // 50px from top
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.makeKeyAndOrderFront(nil)
        self.window = panel
    }
}
