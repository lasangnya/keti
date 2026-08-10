import CoreGraphics
import Foundation

/// Pure shake-detection state machine. Feed it cursor samples as
/// `(x, y, t)`; it reports `true` exactly once when a deliberate
/// back-and-forth shake completes. No AppKit dependencies — fully
/// unit-testable (and shared by the Windows detector via the same logic).
struct ShakeDetector {
    // Tunable detection parameters (mirrors MouseShakeDetector constants).
    let minSegmentPx: CGFloat
    let requiredReversals: Int
    let maxGestureSec: CFTimeInterval
    let staleGapSec: CFTimeInterval
    let minSampleDist: CGFloat
    let cooldownSec: CFTimeInterval

    // Gesture state.
    private var lastX: CGFloat = 0
    private var lastY: CGFloat = 0
    private var lastT: CFTimeInterval = 0
    private var axis = 0                 // 0 = none, 1 = x, 2 = y
    private var lastDir = 0              // +1 / -1
    private var segmentDistance: CGFloat = 0
    private var reversals = 0
    private var gestureStartT: CFTimeInterval = 0
    private var cooldownUntilT: CFTimeInterval = 0

    init(
        minSegmentPx: CGFloat = 30.0,
        requiredReversals: Int = 3,
        maxGestureSec: CFTimeInterval = 0.6,
        staleGapSec: CFTimeInterval = 0.25,
        minSampleDist: CGFloat = 2.0,
        cooldownSec: CFTimeInterval = 1.5
    ) {
        self.minSegmentPx = minSegmentPx
        self.requiredReversals = requiredReversals
        self.maxGestureSec = maxGestureSec
        self.staleGapSec = staleGapSec
        self.minSampleDist = minSampleDist
        self.cooldownSec = cooldownSec
    }

    /// Feeds one cursor sample into the detector. Returns `true` when a
    /// shake completes (caller should stop sampling and dismiss); further
    /// samples during the cooldown window never return `true`.
    mutating func sample(x: CGFloat, y: CGFloat, t: CFTimeInterval) -> Bool {
        // Debounce: ignore samples right after a trigger fired.
        if t < cooldownUntilT {
            lastX = x
            lastY = y
            lastT = t
            return false
        }

        let dt = t - lastT

        // A long pause between samples means the user stopped moving —
        // reset the gesture so a later flurry isn't glued to an old one.
        if dt > staleGapSec {
            axis = 0
            lastDir = 0
            segmentDistance = 0
            reversals = 0
            gestureStartT = t
        }

        let dx = x - lastX
        let dy = y - lastY
        lastX = x
        lastY = y
        lastT = t

        let distance = hypot(dx, dy)
        if distance < minSampleDist { return false }

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
            gestureStartT = t
            return false
        }

        // Switching axes mid-gesture: start over on the new axis.
        if currentAxis != axis {
            axis = currentAxis
            lastDir = dir
            segmentDistance = abs(delta)
            reversals = 0
            gestureStartT = t
            return false
        }

        if dir == lastDir {
            segmentDistance += abs(delta)
        } else {
            // Direction flip — counts as a reversal only if the previous
            // stroke was long enough to be deliberate.
            if segmentDistance >= minSegmentPx {
                reversals += 1
                if reversals >= requiredReversals && (t - gestureStartT) <= maxGestureSec {
                    cooldownUntilT = t + cooldownSec
                    return true
                }
            }
            lastDir = dir
            segmentDistance = abs(delta)
        }

        // The whole gesture must be quick — slow oscillation is not a shake.
        if t - gestureStartT > maxGestureSec {
            axis = 0
            lastDir = 0
            segmentDistance = 0
            reversals = 0
            gestureStartT = t
        }
        return false
    }

    /// Resets all gesture state (equivalent to a fresh detector). Kept for
    /// symmetry with the Windows implementation and test convenience.
    mutating func reset() {
        lastX = 0
        lastY = 0
        lastT = 0
        axis = 0
        lastDir = 0
        segmentDistance = 0
        reversals = 0
        gestureStartT = 0
        cooldownUntilT = 0
    }

    /// Anchors the reference position without starting a gesture. Call after
    /// `reset()` with the current cursor position so the first real sample
    /// measures movement from the actual cursor, not from the origin.
    mutating func seed(x: CGFloat, y: CGFloat, t: CFTimeInterval) {
        lastX = x
        lastY = y
        lastT = t
    }
}
