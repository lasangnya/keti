#ifndef RUNNER_MOUSE_SHAKE_DETECTOR_H_
#define RUNNER_MOUSE_SHAKE_DETECTOR_H_

#include <windows.h>

#include <functional>

namespace keti {

// Windows equivalent of the macOS MouseShakeDetector.
// Polls the cursor position via a timer while a reminder is showing and fires
// a callback when a quick back-and-forth shake of the mouse is detected.
// Start() replaces any running detector; Stop() cancels the timer.
class MouseShakeDetector {
 public:
  using ShakeCallback = std::function<void()>;

  MouseShakeDetector();
  ~MouseShakeDetector();

  // Disable copy.
  MouseShakeDetector(const MouseShakeDetector&) = delete;
  MouseShakeDetector& operator=(const MouseShakeDetector&) = delete;

  // Arms the detector. |hwnd| receives the WM_TIMER ticks and |on_shake| is
  // invoked once when a shake is recognized.
  void Start(HWND hwnd, ShakeCallback on_shake);

  void Stop();

  // Called from the owner window's message handler on WM_TIMER for
  // |kTimerId|.
  void HandleTimer();

  static constexpr UINT kTimerId = 10;

 private:
  void ResetGesture();
  void Sample();

  HWND hwnd_ = nullptr;
  UINT_PTR timer_id_ = 0;
  ShakeCallback on_shake_;

  POINT last_pos_{};
  DWORD last_tick_ = 0;
  int axis_ = 0;   // 0 = none, 1 = x, 2 = y
  int last_dir_ = 0;
  double segment_distance_ = 0;
  int reversals_ = 0;
  DWORD gesture_start_ms_ = 0;
  DWORD cooldown_until_ms_ = 0;

  static constexpr UINT kIntervalMs = 16;       // ~60 Hz
  static constexpr double kMinSegmentPx = 30.0;
  static constexpr int kRequiredReversals = 3;
  static constexpr DWORD kMaxGestureMs = 600;
  static constexpr DWORD kStaleGapMs = 250;
  static constexpr double kMinSampleDist = 2.0;
  static constexpr DWORD kCooldownMs = 1500;
};

}  // namespace keti

#endif  // RUNNER_MOUSE_SHAKE_DETECTOR_H_
