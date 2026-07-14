#include "cursor_pill_manager.h"

namespace keti {

CursorPillManager::CursorPillManager()
    : current_frame_(0),
      offset_x_(0),
      offset_y_(0),
      frame_timer_id_(0),
      cursor_timer_id_(0),
      has_finished_(false) {}

CursorPillManager::~CursorPillManager() {
  Dismiss();
}

void CursorPillManager::Show(HINSTANCE instance,
                             const std::wstring& assets_path,
                             const std::wstring& resource_name,
                             int width,
                             int height,
                             int offset_x,
                             int offset_y,
                             int frame_count,
                             DismissCallback on_dismissed) {
  Dismiss();

  if (!sequence_.Load(assets_path, resource_name, frame_count)) {
    if (on_dismissed) {
      on_dismissed();
    }
    return;
  }

  on_dismissed_ = std::move(on_dismissed);
  offset_x_ = offset_x;
  offset_y_ = offset_y;
  current_frame_ = 0;
  has_finished_ = false;

  if (!window_.Create(instance, L"KetiCursorPill", width, height,
                      /*layered=*/true,
                      /*transparent_for_mouse=*/true,
                      /*topmost=*/true,
                      /*tool_window=*/true,
                      /*no_activate=*/true)) {
    sequence_.Clear();
    if (on_dismissed_) {
      on_dismissed_();
    }
    return;
  }

  window_.SetMessageHandler(
      [this](HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) -> bool {
        if (msg == WM_TIMER && wparam == kFrameTimerId) {
          AdvanceFrame();
          return true;
        }
        if (msg == WM_TIMER && wparam == kCursorTimerId) {
          UpdateCursorPosition();
          return true;
        }
        return false;
      });

  UpdateCursorPosition();

  const PngFrame* frame = sequence_.GetFrame(0);
  if (frame != nullptr) {
    window_.UpdateLayeredContent(frame->dc, frame->width, frame->height);
  }
  window_.Show();

  frame_timer_id_ = SetTimer(window_.handle(), kFrameTimerId, kFrameIntervalMs,
                             nullptr);
  cursor_timer_id_ = SetTimer(window_.handle(), kCursorTimerId,
                              kCursorIntervalMs, nullptr);
}

void CursorPillManager::Dismiss() {
  if (frame_timer_id_ != 0) {
    KillTimer(window_.handle(), frame_timer_id_);
    frame_timer_id_ = 0;
  }
  if (cursor_timer_id_ != 0) {
    KillTimer(window_.handle(), cursor_timer_id_);
    cursor_timer_id_ = 0;
  }
  window_.Destroy();
  sequence_.Clear();
  current_frame_ = 0;
  has_finished_ = false;
  on_dismissed_ = nullptr;
}

bool CursorPillManager::IsShowing() const {
  return window_.IsVisible();
}

void CursorPillManager::AdvanceFrame() {
  if (has_finished_) {
    return;
  }

  int frame_count = sequence_.frame_count();
  if (frame_count == 0) {
    OnDismiss();
    return;
  }

  if (current_frame_ < frame_count - 1) {
    ++current_frame_;
    const PngFrame* frame = sequence_.GetFrame(current_frame_);
    if (frame != nullptr) {
      window_.UpdateLayeredContent(frame->dc, frame->width, frame->height);
    }
  } else {
    has_finished_ = true;
    OnDismiss();
  }
}

void CursorPillManager::UpdateCursorPosition() {
  POINT pt;
  if (!GetCursorPos(&pt)) {
    return;
  }
  window_.SetPosition(pt.x + offset_x_, pt.y + offset_y_);
}

void CursorPillManager::OnDismiss() {
  Dismiss();
  if (on_dismissed_) {
    auto callback = std::move(on_dismissed_);
    callback();
  }
}

}  // namespace keti
