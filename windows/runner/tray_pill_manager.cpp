#include "tray_pill_manager.h"

#include <shellapi.h>
#include <algorithm>

#include "resource.h"

#pragma comment(lib, "shell32.lib")

namespace keti {

namespace {

// The tray reminder is presented as a top-right pill (matching the macOS
// menu-bar position) rather than dropping from the Windows taskbar tray.
constexpr int kCardWidth = 140;
constexpr int kCardHeight = 125;
constexpr int kEdgeMargin = 28;

// Returns the work area of the primary monitor.
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

TrayPillManager::TrayPillManager()
    : instance_(nullptr),
      message_hwnd_(nullptr),
      tray_icon_(nullptr),
      tray_callback_message_(WM_APP + 100),
      tray_icon_added_(false),
      current_frame_(0),
      timer_id_(0),
      has_finished_(false) {}

TrayPillManager::~TrayPillManager() {
  on_shown_ = nullptr;
  on_hidden_ = nullptr;
  Teardown();
}

bool TrayPillManager::Setup(HINSTANCE instance, HWND message_hwnd) {
  if (tray_icon_added_) {
    return true;
  }

  instance_ = instance;
  message_hwnd_ = message_hwnd;

  // Load the application icon as the tray icon.
  tray_icon_ = LoadIconW(instance_, MAKEINTRESOURCE(IDI_APP_ICON));
  if (tray_icon_ == nullptr) {
    tray_icon_ = LoadIconW(nullptr, IDI_APPLICATION);
  }

  NOTIFYICONDATAW nid = {};
  nid.cbSize = sizeof(nid);
  nid.hWnd = message_hwnd_;
  nid.uID = kTrayIconId;
  nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP | NIF_SHOWTIP;
  nid.uCallbackMessage = tray_callback_message_;
  nid.hIcon = tray_icon_;
  wcscpy_s(nid.szTip, L"keti");

  if (!Shell_NotifyIconW(NIM_ADD, &nid)) {
    return false;
  }

  nid.uVersion = NOTIFYICON_VERSION_4;
  Shell_NotifyIconW(NIM_SETVERSION, &nid);

  tray_icon_added_ = true;
  return true;
}

void TrayPillManager::Teardown() {
  Dismiss();

  if (tray_icon_added_ && message_hwnd_ != nullptr) {
    NOTIFYICONDATAW nid = {};
    nid.cbSize = sizeof(nid);
    nid.hWnd = message_hwnd_;
    nid.uID = kTrayIconId;
    Shell_NotifyIconW(NIM_DELETE, &nid);
    tray_icon_added_ = false;
  }

  if (tray_icon_ != nullptr) {
    DestroyIcon(tray_icon_);
    tray_icon_ = nullptr;
  }

  message_hwnd_ = nullptr;
  instance_ = nullptr;
}

void TrayPillManager::Show(const std::wstring& assets_path,
                           const std::wstring& resource_name,
                           int width,
                           int height,
                           int frame_count,
                           Callback on_shown,
                           Callback on_hidden) {
  // Clobber any active reminder, notifying its hidden callback (macOS parity).
  Dismiss();

  if (!tray_icon_added_) {
    if (on_hidden) {
      on_hidden();
    }
    return;
  }

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

  if (!card_window_.Create(instance_, L"KetiTrayCard", kCardWidth, kCardHeight,
                           /*layered=*/true,
                           /*transparent_for_mouse=*/false,
                           /*topmost=*/true,
                           /*tool_window=*/true,
                           /*no_activate=*/true)) {
    sequence_.Clear();
    FireHidden();
    return;
  }

  // Present the reminder as a rounded black pill (macOS TrayCardView parity).
  // corner_diameter == window height gives a full capsule shape; 217 ≈ 85%.
  card_window_.SetRoundedBackground(kCardHeight, 217);

  card_window_.SetMessageHandler(
      [this](HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) -> bool {
        if (msg == WM_TIMER && wparam == kFrameTimerId) {
          AdvanceFrame();
          return true;
        }
        return false;
      });

  PositionCardTopRight();

  const PngFrame* frame = sequence_.GetFrame(0);
  if (frame != nullptr) {
    card_window_.UpdateLayeredContent(frame->dc, frame->width, frame->height);
  }
  card_window_.Show();

  FireShown();

  timer_id_ = SetTimer(card_window_.handle(), kFrameTimerId, kFrameIntervalMs,
                       nullptr);
}

void TrayPillManager::Dismiss() {
  if (timer_id_ != 0) {
    KillTimer(card_window_.handle(), timer_id_);
    timer_id_ = 0;
  }
  card_window_.Destroy();
  sequence_.Clear();
  current_frame_ = 0;
  has_finished_ = false;
  FireHidden();
}

bool TrayPillManager::IsShowing() const {
  return card_window_.IsVisible();
}

void TrayPillManager::FireShown() {
  auto callback = std::move(on_shown_);
  on_shown_ = nullptr;
  if (callback) {
    callback();
  }
}

void TrayPillManager::FireHidden() {
  on_shown_ = nullptr;
  auto callback = std::move(on_hidden_);
  on_hidden_ = nullptr;
  if (callback) {
    callback();
  }
}

void TrayPillManager::HandleTrayMessage(WPARAM wparam, LPARAM lparam) {
  // The tray icon is passive on macOS (the status item has no click handler),
  // so no action is taken here beyond acknowledging the notification.
}

void TrayPillManager::AdvanceFrame() {
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
      card_window_.UpdateLayeredContent(frame->dc, frame->width, frame->height);
    }
  } else {
    has_finished_ = true;
    Dismiss();
  }
}

void TrayPillManager::PositionCardTopRight() {
  // Anchor to the top-right corner of the primary monitor's work area, matching
  // the macOS menu-bar position (where the status item sits).
  RECT work = GetPrimaryWorkArea();
  int x = work.right - kCardWidth - kEdgeMargin;
  int y = work.top + kEdgeMargin;
  card_window_.SetPosition(x, y);
}

}  // namespace keti
