import Cocoa

/// Detects a quick back-and-forth shake of the mouse cursor while a reminder
/// is on screen. Samples cursor position at 60 Hz (the same cadence as the
/// cursor-pill tracking) and counts direction reversals on the dominant axis;
/// fires the `onShake` callback once a deliberate shake completes.
///
/// The detector is armed by the platform-channel layer when a placement
/// reminder is shown and disarmed when it hides. One shake triggers exactly
/// one dismissal — after firing it stops itself.
class MouseShakeDetector {
    private static var timer: Timer?
    private static var onShake: (() -> Void)?

    // Gesture state.
    private static var lastX: CGFloat = 0
    private static var lastY: CGFloat = 0
    private static var lastT: CFTimeInterval = 0
    private static var axis = 0                 // 0 = none, 1 = x, 2 = y
    private static var lastDir = 0              // +1 / -1
    private static var segmentDistance: CGFloat = 0
    private static var reversals = 0
    private static var gestureStartT: CFTimeInterval = 0
    private static var cooldownUntilT: CFTimeInterval = 0

    // Tunable detection parameters.
    private static let sampleInterval: CFTimeInterval = 1.0 / 60.0
    private static let minSegmentPx: CGFloat = 30.0      // one stroke must cover ≥30 px
    private static let requiredReversals = 3             // 3 reversals ⇒ 4 strokes
    private static let maxGestureSec: CFTimeInterval = 0.6  // whole shake ≤ 0.6 s
    private static let staleGapSec: CFTimeInterval = 0.25   // pause longer resets the gesture
    private static let minSampleDist: CGFloat = 2.0      // ignore sub-pixel jitter
    private static let cooldownSec: CFTimeInterval = 1.5

    static func start(onShake: @escaping () -> Void) {
        stop()
        self.onShake = onShake

        let mouse = NSEvent.mouseLocation
        lastX = mouse.x
        lastY = mouse.y
        lastT = CFAbsoluteTimeGetCurrent()
        axis = 0
        lastDir = 0
        segmentDistance = 0
        reversals = 0
        gestureStartT = lastT
        cooldownUntilT = 0

        timer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { _ in
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
        let now = CFAbsoluteTimeGetCurrent()

        // Debounce: ignore samples right after a trigger fired.
        if now < cooldownUntilT {
            let mouse = NSEvent.mouseLocation
            lastX = mouse.x
            lastY = mouse.y
            lastT = now
            return
        }

        let mouse = NSEvent.mouseLocation
        let dt = now - lastT

        // A long pause between samples means the user stopped moving —
        // reset the gesture so a later flurry isn't glued to an old one.
        if dt > staleGapSec {
            axis = 0
            lastDir = 0
            segmentDistance = 0
            reversals = 0
            gestureStartT = now
        }

        let dx = mouse.x - lastX
        let dy = mouse.y - lastY
        lastX = mouse.x
        lastY = mouse.y
        lastT = now

        let distance = hypot(dx, dy)
        if distance < minSampleDist { return }

        // Dominant axis for this sample.
        let dominantX = abs(dx) >= abs(dy)
        let delta = dominantX ? dx : dy
        let currentAxis = dominantX ? 1 : 2
        let dir: Int = delta >= 0 ? 1 : -1

        if axis == 0 {
            // First meaningful stroke of a new gesture.
            axis = currentAxis
            lastDir = dir
            segmentDistance = abs(delta)
            gestureStartT = now
            return
        }

        // Switching axes mid-gesture: start over on the new axis.
        if currentAxis != axis {
            axis = currentAxis
            lastDir = dir
            segmentDistance = abs(delta)
            reversals = 0
            gestureStartT = now
            return
        }

        if dir == lastDir {
            segmentDistance += abs(delta)
        } else {
            // Direction flip — counts as a reversal only if the previous
            // stroke was long enough to be deliberate.
            if segmentDistance >= minSegmentPx {
                reversals += 1
                if reversals >= requiredReversals && (now - gestureStartT) <= maxGestureSec {
                    print("[MouseShakeDetector] ⚡ Shake detected — reversals=\(reversals)")
                    stop()
                    cooldownUntilT = now + cooldownSec
                    onShake()
                    return
                }
            }
            lastDir = dir
            segmentDistance = abs(delta)
        }

        // The whole gesture must be quick — slow oscillation is not a shake.
        if now - gestureStartT > maxGestureSec {
            axis = 0
            lastDir = 0
            segmentDistance = 0
            reversals = 0
            gestureStartT = now
        }
    }
}
