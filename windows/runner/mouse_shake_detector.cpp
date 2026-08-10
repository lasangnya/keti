#include "mouse_shake_detector.h"

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
    detector_.Seed(pt.x, pt.y, GetTickCount64());
  }

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

void MouseShakeDetector::Sample() {
  POINT pt;
  if (!GetCursorPos(&pt)) {
    return;
  }
  if (detector_.Sample(pt.x, pt.y, GetTickCount64())) {
    auto callback = std::move(on_shake_);
    Stop();
    if (callback) {
      callback();
    }
  }
}

}  // namespace keti
