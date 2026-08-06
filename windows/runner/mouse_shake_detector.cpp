#include "mouse_shake_detector.h"

#include <cmath>

namespace keti {

MouseShakeDetector::MouseShakeDetector() = default;

MouseShakeDetector::~MouseShakeDetector() {
  Stop();
}

void MouseShakeDetector::Start(HWND hwnd, ShakeCallback on_shake) {
  Stop();

  hwnd_ = hwnd;
  on_shake_ = std::move(on_shake);

  POINT pt;
  if (GetCursorPos(&pt)) {
    last_pos_ = pt;
  }
  last_tick_ = GetTickCount();
  ResetGesture();
  cooldown_until_ms_ = 0;

  timer_id_ = SetTimer(hwnd_, kTimerId, kIntervalMs, nullptr);
}

void MouseShakeDetector::Stop() {
  if (timer_id_ != 0 && hwnd_ != nullptr) {
    KillTimer(hwnd_, timer_id_);
  }
  timer_id_ = 0;
  hwnd_ = nullptr;
  on_shake_ = nullptr;
}

void MouseShakeDetector::HandleTimer() {
  if (on_shake_ == nullptr) {
    return;
  }
  Sample();
}

void MouseShakeDetector::ResetGesture() {
  axis_ = 0;
  last_dir_ = 0;
  segment_distance_ = 0;
  reversals_ = 0;
  gesture_start_ms_ = 0;
}

void MouseShakeDetector::Sample() {
  const DWORD now = GetTickCount();
  if (now < cooldown_until_ms_) {
    POINT pt;
    if (GetCursorPos(&pt)) {
      last_pos_ = pt;
    }
    last_tick_ = now;
    return;
  }

  POINT pt;
  if (!GetCursorPos(&pt)) {
    return;
  }

  const double dx = static_cast<double>(pt.x) - last_pos_.x;
  const double dy = static_cast<double>(pt.y) - last_pos_.y;
  last_pos_ = pt;

  const DWORD dt = now - last_tick_;
  last_tick_ = now;

  if (dt > kStaleGapMs) {
    ResetGesture();
    gesture_start_ms_ = now;
  }

  const double distance = std::hypot(dx, dy);
  if (distance < kMinSampleDist) {
    return;
  }

  const bool dominant_x = std::abs(dx) >= std::abs(dy);
  const double delta = dominant_x ? dx : dy;
  const int current_axis = dominant_x ? 1 : 2;
  const int dir = delta >= 0 ? 1 : -1;

  if (axis_ == 0) {
    axis_ = current_axis;
    last_dir_ = dir;
    segment_distance_ = std::abs(delta);
    gesture_start_ms_ = now;
    return;
  }

  if (current_axis != axis_) {
    axis_ = current_axis;
    last_dir_ = dir;
    segment_distance_ = std::abs(delta);
    reversals_ = 0;
    gesture_start_ms_ = now;
    return;
  }

  if (dir == last_dir_) {
    segment_distance_ += std::abs(delta);
  } else {
    if (segment_distance_ >= kMinSegmentPx) {
      ++reversals_;
      if (reversals_ >= kRequiredReversals &&
          (now - gesture_start_ms_) <= kMaxGestureMs) {
        auto callback = std::move(on_shake_);
        Stop();
        cooldown_until_ms_ = now + kCooldownMs;
        if (callback) {
          callback();
        }
        return;
      }
    }
    last_dir_ = dir;
    segment_distance_ = std::abs(delta);
  }

  if (now - gesture_start_ms_ > kMaxGestureMs) {
    ResetGesture();
    gesture_start_ms_ = now;
  }
}

}  // namespace keti
