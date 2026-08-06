import XCTest

/// Unit tests for the pure `ShakeDetector` state machine (the algorithm
/// behind mouse-shake reminder dismissal). Cursor samples are synthetic, so
/// no real mouse or AppKit is involved.
final class ShakeDetectorTests: XCTestCase {
    private var detector: ShakeDetector!

    override func setUp() {
        super.setUp()
        detector = ShakeDetector()
    }

    /// Builds a horizontal shake: `requiredReversals` direction flips with
    /// strokes of `amplitude` px, sampled every `intervalMs`, returning
    /// whether the detector fired.
    @discardableResult
    private func feedHorizontalShake(
        amplitude: CGFloat = 50,
        intervalMs: Double = 16,
        flips: Int = 3,
        y: CGFloat = 100
    ) -> Bool {
        var fired = false
        var x: CGFloat = 0
        var direction: CGFloat = 1
        var t: CFTimeInterval = 0
        detector.seed(x: x, y: y, t: t)

        // One stroke per flip, plus one final return stroke.
        for _ in 0...(flips + 1) {
            x += direction * amplitude
            t += intervalMs / 1000.0
            if detector.sample(x: x, y: y, t: t) {
                fired = true
            }
            direction *= -1
        }
        return fired
    }

    func testQuickHorizontalShakeTriggers() {
        XCTAssertTrue(feedHorizontalShake(), "A fast 3-reversal horizontal shake should be detected")
    }

    func testSlowHorizontalDriftDoesNotTrigger() {
        // Same geometry but 20x slower — exceeds maxGestureSec, must not fire.
        XCTAssertFalse(feedHorizontalShake(intervalMs: 320), "A slow oscillation is not a shake")
    }

    func testTinyAmplitudeDoesNotTrigger() {
        // Strokes below minSegmentPx never count as reversals.
        XCTAssertFalse(feedHorizontalShake(amplitude: 5), "Sub-threshold jitter must be ignored")
    }

    func testSingleDirectionMovementDoesNotTrigger() {
        detector.seed(x: 0, y: 100, t: 0)
        var fired = false
        var x: CGFloat = 0
        for step in 1...12 {
            x = CGFloat(step) * 50
            if detector.sample(x: x, y: 100, t: Double(step) * 0.016) {
                fired = true
            }
        }
        XCTAssertFalse(fired, "Continuous movement in one direction is not a shake")
    }

    func testVerticalShakeTriggers() {
        var fired = false
        var y: CGFloat = 0
        var direction: CGFloat = 1
        var t: CFTimeInterval = 0
        detector.seed(x: 200, y: y, t: t)
        for _ in 0...4 {
            y += direction * 50
            t += 0.016
            if detector.sample(x: 200, y: y, t: t) {
                fired = true
            }
            direction *= -1
        }
        XCTAssertTrue(fired, "A fast vertical shake should be detected")
    }

    func testCooldownSuppressesSecondTrigger() {
        XCTAssertTrue(feedHorizontalShake(), "First shake fires")
        // Immediately continue the same motion — must not fire again.
        var firedAgain = false
        var x: CGFloat = 200
        var direction: CGFloat = 1
        var t: CFTimeInterval = 0.09  // right after the first shake finished
        for _ in 0...4 {
            x += direction * 50
            t += 0.016
            if detector.sample(x: x, y: 100, t: t) {
                firedAgain = true
            }
            direction *= -1
        }
        XCTAssertFalse(firedAgain, "Cooldown must suppress a second trigger from the same gesture")
    }

    func testStalePauseResetsGesture() {
        detector.seed(x: 0, y: 100, t: 0)
        var fired = false

        // Burst A: two reversals (+50, -50, +50) — not enough to fire.
        var t: CFTimeInterval = 0
        for x in [CGFloat(50), 0, 50] {
            t += 0.016
            if detector.sample(x: x, y: 100, t: t) {
                fired = true
            }
        }
        XCTAssertFalse(fired, "Two reversals must not fire yet")

        // Long pause (stale) resets the gesture state.
        t += 0.5
        detector.sample(x: 0, y: 100, t: t)

        // Burst B: only two reversals (+50, -50). If the pause had NOT reset
        // the counter, the cumulative 4 reversals would fire here; with the
        // reset it stays at 2 and must not fire.
        for x in [CGFloat(50), 0] {
            t += 0.016
            if detector.sample(x: x, y: 100, t: t) {
                fired = true
            }
        }
        XCTAssertFalse(fired, "A stale pause resets the gesture, so the burst must restart")
    }
}
