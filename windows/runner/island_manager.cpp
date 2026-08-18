#include "island_manager.h"

namespace keti {

namespace {

// Returns the work area of the monitor that should host the island.
// Falls back to the primary monitor work area.
RECT GetPrimaryWorkArea() {
  POINT pt = {0, 0};
  HMONITOR monitor = MonitorFromPoint(pt, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO info = {};
  info.cbSize = sizeof(info);
  if (GetMonitorInfoW(monitor, &info)) {
    return info.rcWork;
  }

  RECT fallback;
  SystemParametersInfoW(SPI_GETWORKAREA, 0, &fallback, 0);
  return fallback;
}

}  // namespace

IslandManager::IslandManager()
    : current_frame_(0),
      timer_id_(0),
      has_finished_(false) {}

IslandManager::~IslandManager() {
  on_shown_ = nullptr;
  on_hidden_ = nullptr;
  Dismiss();
}

void IslandManager::Show(HINSTANCE instance,
                         const std::wstring& assets_path,
                         const std::wstring& resource_name,
                         int width,
                         int height,
                         int frame_count,
                         Callback on_shown,
                         Callback on_hidden) {
  // Clobber any active reminder, notifying its hidden callback (macOS parity).
  Dismiss();

  if (!sequence_.Load(assets_path, resource_name, frame_count)) {
    if (on_hidden) {
      on_hidden();
    }
    return;
  }

  on_shown_ = std::move(on_shown);
  on_hidden_ = std::move(on_hidden);
  current_frame_ = 0;
  has_finished_ = false;

  if (!window_.Create(instance, L"KetiIsland", width, height,
                      /*layered=*/true,
                      /*transparent_for_mouse=*/false,
                      /*topmost=*/true,
                      /*tool_window=*/true,
                      /*no_activate=*/true)) {
    sequence_.Clear();
    FireHidden();
    return;
  }

  window_.SetMessageHandler(
      [this](HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) -> bool {
        if (msg == WM_TIMER && wparam == kFrameTimerId) {
          AdvanceFrame();
          return true;
        }
        return false;
      });

  // Position at the top center of the primary monitor work area.
  RECT work = GetPrimaryWorkArea();
  int x = (work.left + work.right - width) / 2;
  int y = work.top + 5;
  window_.SetPosition(x, y);

  // Show the first frame.
  const PngFrame* frame = sequence_.GetFrame(0);
  if (frame != nullptr) {
    window_.UpdateLayeredContent(frame->dc, frame->width, frame->height);
  }
  window_.Show();

  FireShown();

  timer_id_ = SetTimer(window_.handle(), kFrameTimerId, kFrameIntervalMs,
                       nullptr);
}

void IslandManager::Dismiss() {
  if (timer_id_ != 0) {
    KillTimer(window_.handle(), timer_id_);
    timer_id_ = 0;
  }
  window_.Destroy();
  sequence_.Clear();
  current_frame_ = 0;
  has_finished_ = false;
  FireHidden();
}

bool IslandManager::IsShowing() const {
  return window_.IsVisible();
}

void IslandManager::FireShown() {
  auto callback = std::move(on_shown_);
  on_shown_ = nullptr;
  if (callback) {
    callback();
  }
}

void IslandManager::FireHidden() {
  on_shown_ = nullptr;
  auto callback = std::move(on_hidden_);
  on_hidden_ = nullptr;
  if (callback) {
    callback();
  }
}

void IslandManager::AdvanceFrame() {
  if (has_finished_) {
    return;
  }

  int frame_count = sequence_.frame_count();
  if (frame_count == 0) {
    Dismiss();
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
    Dismiss();
  }
}

}  // namespace keti
