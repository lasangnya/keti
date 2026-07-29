import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame

        let notchChannel = FlutterMethodChannel(name: PlatformChannels.notchHook, binaryMessenger: flutterViewController.engine.binaryMessenger)
        let cursorChannel = FlutterMethodChannel(name: PlatformChannels.cursorPill, binaryMessenger: flutterViewController.engine.binaryMessenger)
        let trayChannel = FlutterMethodChannel(name: PlatformChannels.trayPill, binaryMessenger: flutterViewController.engine.binaryMessenger)
        let complianceChannel = FlutterMethodChannel(name: PlatformChannels.complianceCard, binaryMessenger: flutterViewController.engine.binaryMessenger)
        let sessionChannel = FlutterMethodChannel(name: PlatformChannels.sessionLifecycle, binaryMessenger: flutterViewController.engine.binaryMessenger)

        notchChannel.setMethodCallHandler { (call, result) in
            if call.method == PlatformChannels.methodShowIsland {
                let args = call.arguments as? [String: Any]
                let reminderId = args?[PlatformChannels.keyReminderId] as? String ?? "unknown"
                let message = args?[PlatformChannels.keyMessage] as? String ?? "Reminder!"
                let resourceName = args?[PlatformChannels.keyResourceName] as? String ?? "ambient_break_cursor_pill"
                let width = args?[PlatformChannels.keyWidth] as? Double ?? 350
                let height = args?[PlatformChannels.keyHeight] as? Double ?? 60
                let totalFrames = args?[PlatformChannels.keyTotalFrames] as? Int ?? 120
                let visibilityMs = args?[PlatformChannels.keyVisibilityMs] as? Int ?? 5000

                IslandManager.show(message: message, resourceName: resourceName, width: width, height: height, totalFrames: totalFrames, visibilityMs: visibilityMs, onShown: {
                    notchChannel.invokeMethod(PlatformChannels.methodOnShown, arguments: reminderId)
                }, onHidden: {
                    notchChannel.invokeMethod(PlatformChannels.methodOnHidden, arguments: reminderId)
                })
                result(nil)
            }
        }

        cursorChannel.setMethodCallHandler { (call, result) in
            if call.method == PlatformChannels.methodShowCursorPill {
                let args = call.arguments as? [String: Any]
                let reminderId = args?[PlatformChannels.keyReminderId] as? String ?? "unknown"
                let resourceName = args?[PlatformChannels.keyResourceName] as? String ?? "ambient_break_cursor_pill"
                let width = args?[PlatformChannels.keyWidth] as? Double ?? 150
                let height = args?[PlatformChannels.keyHeight] as? Double ?? 150
                let offsetX = args?[PlatformChannels.keyOffsetX] as? Double ?? 0
                let offsetY = args?[PlatformChannels.keyOffsetY] as? Double ?? 0
                let totalFrames = args?[PlatformChannels.keyTotalFrames] as? Int ?? 120
                let visibilityMs = args?[PlatformChannels.keyVisibilityMs] as? Int ?? 5000

                CursorPillManager.show(resourceName: resourceName, width: width, height: height, offsetX: offsetX, offsetY: offsetY, totalFrames: totalFrames, visibilityMs: visibilityMs, onShown: {
                    cursorChannel.invokeMethod(PlatformChannels.methodOnShown, arguments: reminderId)
                }, onHidden: {
                    cursorChannel.invokeMethod(PlatformChannels.methodOnHidden, arguments: reminderId)
                })
                result(nil)
            }
        }

        trayChannel.setMethodCallHandler { (call, result) in
            if call.method == PlatformChannels.methodShowTrayPill {
                let args = call.arguments as? [String: Any]
                let reminderId = args?[PlatformChannels.keyReminderId] as? String ?? "unknown"
                let message = args?[PlatformChannels.keyMessage] as? String ?? "Reminder!"
                let resourceName = args?[PlatformChannels.keyResourceName] as? String ?? "drop.fill"
                let width = args?[PlatformChannels.keyWidth] as? Double ?? 22
                let height = args?[PlatformChannels.keyHeight] as? Double ?? 22
                let totalFrames = args?[PlatformChannels.keyTotalFrames] as? Int ?? 120
                let visibilityMs = args?[PlatformChannels.keyVisibilityMs] as? Int ?? 5000

                TrayPillManager.show(message: message, resourceName: resourceName, width: width, height: height, totalFrames: totalFrames, visibilityMs: visibilityMs, onShown: {
                    trayChannel.invokeMethod(PlatformChannels.methodOnShown, arguments: reminderId)
                }, onHidden: {
                    trayChannel.invokeMethod(PlatformChannels.methodOnHidden, arguments: reminderId)
                })
                result(nil)
            }
        }

        complianceChannel.setMethodCallHandler { (call, result) in
            if call.method == PlatformChannels.methodShowComplianceCard {
                let args = call.arguments as? [String: Any]
                let reminderId = args?[PlatformChannels.keyReminderId] as? String ?? "unknown"
                let question = args?[PlatformChannels.keyQuestion] as? String ?? "Did you do it?"
                let b1 = args?[PlatformChannels.keyButton1Text] as? String ?? "Done"
                let b2 = args?[PlatformChannels.keyButton2Text] as? String ?? "Not now"
                let timeoutMs = args?[PlatformChannels.keyTimeoutMs] as? Int ?? 120000

                ComplianceCardManager.show(question: question, button1Text: b1, button2Text: b2, timeoutMs: timeoutMs, onAction: { action in
                    complianceChannel.invokeMethod(PlatformChannels.methodOnCardAction, arguments: [
                        PlatformChannels.keyReminderId: reminderId,
                        PlatformChannels.keyAction: action,
                    ])
                }, onTimeout: {
                    complianceChannel.invokeMethod(PlatformChannels.methodOnCardTimeout, arguments: reminderId)
                })
                result(nil)
            }
        }

        sessionChannel.setMethodCallHandler { (call, result) in
            if call.method == PlatformChannels.methodSetSessionActive, let active = call.arguments as? Bool {
                (NSApp.delegate as? AppDelegate)?.setSessionActive(active)
            }
            result(nil)
        }

        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        RegisterGeneratedPlugins(registry: flutterViewController)
        super.awakeFromNib()
    }
}
