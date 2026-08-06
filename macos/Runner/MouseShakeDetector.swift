import Cocoa

/// Detects a quick back-and-forth shake of the mouse cursor while a reminder
/// is on screen. Polls cursor position at 60 Hz (the same cadence as the
/// cursor-pill tracking) and feeds the pure [ShakeDetector] state machine;
/// fires the `onShake` callback once a deliberate shake completes.
///
/// The detector is armed by the platform-channel layer when a placement
/// reminder is shown and disarmed when it hides. One shake triggers exactly
/// one dismissal — after firing it stops itself.
class MouseShakeDetector {
    private static var timer: Timer?
    private static var onShake: (() -> Void)?
    private static var detector = ShakeDetector()

    static func start(onShake: @escaping () -> Void) {
        stop()
        self.onShake = onShake

        var fresh = ShakeDetector()
        let mouse = NSEvent.mouseLocation
        fresh.seed(x: mouse.x, y: mouse.y, t: CFAbsoluteTimeGetCurrent())
        detector = fresh

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            sample()
        }
    }

    static func stop() {
        timer?.invalidate()
        timer = nil
        onShake = nil
    }

    private static func sample() {
        guard let onShake = onShake else { return }
        let mouse = NSEvent.mouseLocation
        if detector.sample(x: mouse.x, y: mouse.y, t: CFAbsoluteTimeGetCurrent()) {
            print("[MouseShakeDetector] ⚡ Shake detected")
            stop()
            onShake()
        }
    }
}
