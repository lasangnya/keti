#include "cursor_pill_manager.h"

namespace keti {

namespace {

// Helper to scale logical points from Flutter into physical pixels based on monitor DPI.
int ScalePx(int logical, int dpi) {
  return MulDiv(logical, dpi, 96);
}

// Returns the DPI of the monitor currently containing the cursor.
int GetActiveDPI() {
  POINT pt = {0, 0};
  GetCursorPos(&pt);
  HMONITOR monitor = MonitorFromPoint(pt, MONITOR_DEFAULTTONEAREST);

  UINT dpi_x, dpi_y;
  HMODULE shcore = LoadLibraryW(L"Shcore.dll");
  if (shcore) {
    using GetDpiForMonitorFn = HRESULT(WINAPI*)(HMONITOR, int, UINT*, UINT*);
    auto get_dpi = reinterpret_cast<GetDpiForMonitorFn>(GetProcAddress(shcore, "GetDpiForMonitor"));
    if (get_dpi && SUCCEEDED(get_dpi(monitor, 0 /* MDT_EFFECTIVE_DPI */, &dpi_x, &dpi_y))) {
      FreeLibrary(shcore);
      return static_cast<int>(dpi_x);
    }
    FreeLibrary(shcore);
  }
  return 96;
}

}  // namespace

CursorPillManager::CursorPillManager()
    : current_frame_(0),
      offset_x_(0),
      offset_y_(0),
      frame_timer_id_(0),
      cursor_timer_id_(0),
      has_finished_(false) {}

CursorPillManager::~CursorPillManager() {
  on_shown_ = nullptr;
  on_hidden_ = nullptr;
  Dismiss();
}

void CursorPillManager::Show(HINSTANCE instance,
                             const std::wstring& assets_path,
                             const std::wstring& resource_name,
                             int logical_width,
                             int logical_height,
                             int logical_offset_x,
                             int logical_offset_y,
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

  int dpi = GetActiveDPI();
  offset_x_ = ScalePx(logical_offset_x, dpi);
  offset_y_ = ScalePx(logical_offset_y, dpi);
  int physical_width = ScalePx(logical_width, dpi);
  int physical_height = ScalePx(logical_height, dpi);

  current_frame_ = 0;
  has_finished_ = false;

  if (!window_.Create(instance, L"KetiCursorPill", physical_width, physical_height,
                      /*layered=*/true,
                      /*transparent_for_mouse=*/true,
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

  FireShown();

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
  FireHidden();
}

bool CursorPillManager::IsShowing() const {
  return window_.IsVisible();
}

void CursorPillManager::FireShown() {
  auto callback = std::move(on_shown_);
  on_shown_ = nullptr;
  if (callback) {
    callback();
  }
}

void CursorPillManager::FireHidden() {
  on_shown_ = nullptr;
  auto callback = std::move(on_hidden_);
  on_hidden_ = nullptr;
  if (callback) {
    callback();
  }
}

void CursorPillManager::AdvanceFrame() {
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

void CursorPillManager::UpdateCursorPosition() {
  POINT pt;
  if (!GetCursorPos(&pt)) {
    return;
  }
  window_.SetPosition(pt.x + offset_x_, pt.y + offset_y_);
}

}  // namespace keti
