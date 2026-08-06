#include "shake_detector.h"

#include <cmath>

namespace keti {

ShakeDetector::ShakeDetector() = default;

bool ShakeDetector::Sample(double x, double y, uint64_t time_ms) {
  if (time_ms < cooldown_until_ms_) {
    last_x_ = x;
    last_y_ = y;
    last_t_ms_ = time_ms;
    return false;
  }

  const uint64_t dt = time_ms - last_t_ms_;

  if (dt > kStaleGapMs) {
    axis_ = 0;
    last_dir_ = 0;
    segment_distance_ = 0;
    reversals_ = 0;
    gesture_start_ms_ = time_ms;
  }

  const double dx = x - last_x_;
  const double dy = y - last_y_;
  last_x_ = x;
  last_y_ = y;
  last_t_ms_ = time_ms;

  const double distance = std::hypot(dx, dy);
  if (distance < kMinSampleDist) {
    return false;
  }

  const bool dominant_x = std::abs(dx) >= std::abs(dy);
  const double delta = dominant_x ? dx : dy;
  const int current_axis = dominant_x ? 1 : 2;
  const int dir = delta >= 0 ? 1 : -1;

  if (axis_ == 0) {
    axis_ = current_axis;
    last_dir_ = dir;
    segment_distance_ = std::abs(delta);
    gesture_start_ms_ = time_ms;
    return false;
  }

  if (current_axis != axis_) {
    axis_ = current_axis;
    last_dir_ = dir;
    segment_distance_ = std::abs(delta);
    reversals_ = 0;
    gesture_start_ms_ = time_ms;
    return false;
  }

  if (dir == last_dir_) {
    segment_distance_ += std::abs(delta);
  } else {
    if (segment_distance_ >= kMinSegmentPx) {
      ++reversals_;
      if (reversals_ >= kRequiredReversals &&
          (time_ms - gesture_start_ms_) <= kMaxGestureMs) {
        cooldown_until_ms_ = time_ms + kCooldownMs;
        return true;
      }
    }
    last_dir_ = dir;
    segment_distance_ = std::abs(delta);
  }

  if (time_ms - gesture_start_ms_ > kMaxGestureMs) {
    axis_ = 0;
    last_dir_ = 0;
    segment_distance_ = 0;
    reversals_ = 0;
    gesture_start_ms_ = time_ms;
  }
  return false;
}

void ShakeDetector::Seed(double x, double y, uint64_t time_ms) {
  last_x_ = x;
  last_y_ = y;
  last_t_ms_ = time_ms;
}

void ShakeDetector::Reset() {
  last_x_ = 0;
  last_y_ = 0;
  last_t_ms_ = 0;
  axis_ = 0;
  last_dir_ = 0;
  segment_distance_ = 0;
  reversals_ = 0;
  gesture_start_ms_ = 0;
  cooldown_until_ms_ = 0;
}

}  // namespace keti
