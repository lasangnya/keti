#ifndef RUNNER_MOUSE_SHAKE_DETECTOR_H_
#define RUNNER_MOUSE_SHAKE_DETECTOR_H_

#include <windows.h>

#include <functional>

#include "shake_detector.h"

namespace keti {

// Windows equivalent of the macOS MouseShakeDetector.
// Polls the cursor position via a timer while a reminder is showing and feeds
// the pure ShakeDetector state machine; fires a callback when a quick
// back-and-forth shake of the mouse is detected.
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
  void Sample();

  HWND hwnd_ = nullptr;
  UINT_PTR timer_id_ = 0;
  ShakeCallback on_shake_;
  ShakeDetector detector_;

  static constexpr UINT kIntervalMs = 16;  // ~60 Hz
};

}  // namespace keti

#endif  // RUNNER_MOUSE_SHAKE_DETECTOR_H_
