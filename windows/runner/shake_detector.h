#ifndef RUNNER_SHAKE_DETECTOR_H_
#define RUNNER_SHAKE_DETECTOR_H_

#include <cstdint>

namespace keti {

// Pure shake-detection state machine, mirroring the macOS ShakeDetector.
// Feed it cursor samples as (x, y, time_ms); Sample() returns true exactly
// once when a deliberate back-and-forth shake completes. No Windows
// dependencies — unit-testable without a real cursor.
class ShakeDetector {
 public:
  ShakeDetector();
  ~ShakeDetector() = default;

  ShakeDetector(const ShakeDetector&) = delete;
  ShakeDetector& operator=(const ShakeDetector&) = delete;

  // Feeds one cursor sample. Returns true when a shake completes.
  bool Sample(double x, double y, uint64_t time_ms);

  // Anchors the reference position without starting a gesture.
  void Seed(double x, double y, uint64_t time_ms);

  // Resets all gesture state.
  void Reset();

  // Tunable detection parameters (mirrors the macOS defaults).
  static constexpr double kMinSegmentPx = 30.0;
  static constexpr int kRequiredReversals = 3;
  static constexpr uint64_t kMaxGestureMs = 600;
  static constexpr uint64_t kStaleGapMs = 250;
  static constexpr double kMinSampleDist = 2.0;
  static constexpr uint64_t kCooldownMs = 1500;

 private:
  double last_x_ = 0;
  double last_y_ = 0;
  uint64_t last_t_ms_ = 0;
  int axis_ = 0;  // 0 = none, 1 = x, 2 = y
  int last_dir_ = 0;
  double segment_distance_ = 0;
  int reversals_ = 0;
  uint64_t gesture_start_ms_ = 0;
  uint64_t cooldown_until_ms_ = 0;
};

}  // namespace keti

#endif  // RUNNER_SHAKE_DETECTOR_H_
