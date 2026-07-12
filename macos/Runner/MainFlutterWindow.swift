import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        print("MainFlutterWindow: awakeFromNib called")
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        let notchChannel = FlutterMethodChannel(name: PlatformChannels.notchHook, binaryMessenger: flutterViewController.engine.binaryMessenger)
        let cursorChannel = FlutterMethodChannel(name: PlatformChannels.cursorPill, binaryMessenger: flutterViewController.engine.binaryMessenger)
        let trayChannel = FlutterMethodChannel(name: PlatformChannels.trayPill, binaryMessenger: flutterViewController.engine.binaryMessenger)

      notchChannel.setMethodCallHandler { (call, result) in
        print("MainFlutterWindow: notchChannel call: \(call.method)")
        if call.method == PlatformChannels.methodShowIsland {
          let args = call.arguments as? [String: Any]
          let message = args?[PlatformChannels.keyMessage] as? String ?? "Reminder!"
          let resourceName = args?[PlatformChannels.keyResourceName] as? String ?? "ambient_break_cursor_pill"
          let width = args?[PlatformChannels.keyWidth] as? Double ?? 350
          let height = args?[PlatformChannels.keyHeight] as? Double ?? 60
          
          // Call the SwiftUI Manager
          IslandManager.show(message: message, resourceName: resourceName, width: width, height: height)
          result(nil)
        }
      }

      cursorChannel.setMethodCallHandler { (call, result) in
        if call.method == PlatformChannels.methodShowCursorPill {
            let args = call.arguments as? [String : Any]
            let resourceName = args?[PlatformChannels.keyResourceName] as? String ?? "ambient_break_cursor_pill"
            let width = args?[PlatformChannels.keyWidth] as? Double ?? 150
            let height = args?[PlatformChannels.keyHeight] as? Double ?? 150
            let offsetX = args?[PlatformChannels.keyOffsetX] as? Double ?? 0
            let offsetY = args?[PlatformChannels.keyOffsetY] as? Double ?? 0
            
            CursorPillManager.show(
                resourceName: resourceName,
                width: width,
                height: height,
                offsetX: offsetX,
                offsetY: offsetY
            )
          result(nil)
        }
      }

      trayChannel.setMethodCallHandler { (call, result) in
        if call.method == PlatformChannels.methodShowTrayPill {
            let args = call.arguments as? [String : Any]
            let resourceName = args?[PlatformChannels.keyResourceName] as? String ?? "drop.fill"
          TrayPillManager.show(resourceName: resourceName)
          result(nil)
        }
      }

        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }
}
