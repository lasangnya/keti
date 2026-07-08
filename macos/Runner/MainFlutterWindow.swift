import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        let channel = FlutterMethodChannel(name: "app.keti/notch_hook", binaryMessenger: flutterViewController.engine.binaryMessenger)

      channel.setMethodCallHandler { (call, result) in
        if call.method == "showIsland" {
          let args = call.arguments as? [String: Any]
          let message = args?["message"] as? String ?? "Reminder!"
          // Call the SwiftUI Manager
          IslandManager.show(message: message)
          result(nil)
        }
      }

        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }
}
