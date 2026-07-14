#include "tray_pill_manager.h"

#include <shellapi.h>

#include "resource.h"

#pragma comment(lib, "shell32.lib")

namespace keti {

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
                           DismissCallback on_dismissed) {
  Dismiss();

  if (!tray_icon_added_) {
    if (on_dismissed) {
      on_dismissed();
    }
    return;
  }

  if (!sequence_.Load(assets_path, resource_name, frame_count)) {
    if (on_dismissed) {
      on_dismissed();
    }
    return;
  }

  on_dismissed_ = std::move(on_dismissed);
  current_frame_ = 0;
  has_finished_ = false;

  if (!card_window_.Create(instance_, L"KetiTrayCard", width, height,
                           /*layered=*/true,
                           /*transparent_for_mouse=*/false,
                           /*topmost=*/true,
                           /*tool_window=*/true,
                           /*no_activate=*/true)) {
    sequence_.Clear();
    if (on_dismissed_) {
      on_dismissed_();
    }
    return;
  }

  card_window_.SetMessageHandler(
      [this](HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) -> bool {
        if (msg == WM_TIMER && wparam == kFrameTimerId) {
          AdvanceFrame();
          return true;
        }
        if (msg == WM_LBUTTONUP) {
          OnDismiss();
          return true;
        }
        return false;
      });

  PositionCardUnderTray();

  const PngFrame* frame = sequence_.GetFrame(0);
  if (frame != nullptr) {
    card_window_.UpdateLayeredContent(frame->dc, frame->width, frame->height);
  }
  card_window_.Show();

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
  on_dismissed_ = nullptr;
}

bool TrayPillManager::IsShowing() const {
  return card_window_.IsVisible();
}

void TrayPillManager::HandleTrayMessage(WPARAM wparam, LPARAM lparam) {
  // wparam holds the icon ID; lparam holds the notification.
  if (LOWORD(lparam) == WM_LBUTTONUP) {
    // Clicking the tray icon dismisses any active card.
    if (IsShowing()) {
      OnDismiss();
    }
  }
}

void TrayPillManager::AdvanceFrame() {
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
      card_window_.UpdateLayeredContent(frame->dc, frame->width, frame->height);
    }
  } else {
    has_finished_ = true;
    OnDismiss();
  }
}

void TrayPillManager::PositionCardUnderTray() {
  NOTIFYICONIDENTIFIER nii = {};
  nii.cbSize = sizeof(nii);
  nii.hWnd = message_hwnd_;
  nii.uID = kTrayIconId;

  RECT icon_rect;
  HRESULT hr = Shell_NotifyIconGetRect(&nii, &icon_rect);

  HWND hwnd = card_window_.handle();
  RECT window_rect = {};
  if (hwnd != nullptr) {
    GetWindowRect(hwnd, &window_rect);
  }
  int window_width = window_rect.right - window_rect.left;
  if (window_width <= 0) {
    window_width = 200;
  }

  int x = 0;
  int y = 0;

  if (SUCCEEDED(hr)) {
    int icon_center = (icon_rect.left + icon_rect.right) / 2;
    x = icon_center - (window_width / 2);
    y = icon_rect.bottom + 4;  // 4px gap below the tray icon
  } else {
    POINT pt;
    if (GetCursorPos(&pt)) {
      x = pt.x - (window_width / 2);
      y = pt.y + 4;
    }
  }

  card_window_.SetPosition(x, y);
}

void TrayPillManager::OnDismiss() {
  Dismiss();
  if (on_dismissed_) {
    auto callback = std::move(on_dismissed_);
    callback();
  }
}

}  // namespace keti
