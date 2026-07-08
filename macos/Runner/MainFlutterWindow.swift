import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        let notchChannel = FlutterMethodChannel(name: PlatformChannels.notchHook, binaryMessenger: flutterViewController.engine.binaryMessenger)
        let cursorChannel = FlutterMethodChannel(name: PlatformChannels.cursorPill, binaryMessenger: flutterViewController.engine.binaryMessenger)

      notchChannel.setMethodCallHandler { (call, result) in
        if call.method == PlatformChannels.methodShowIsland {
          let args = call.arguments as? [String: Any]
          let message = args?[PlatformChannels.keyMessage] as? String ?? "Reminder!"
          // Call the SwiftUI Manager
          IslandManager.show(message: message)
          result(nil)
        }
      }

      cursorChannel.setMethodCallHandler { (call, result) in
        if call.method == PlatformChannels.methodShowCursorPill {
          CursorPillManager.show()
          result(nil)
        }
      }

        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }
}
