#ifndef RUNNER_TRAY_PILL_MANAGER_H_
#define RUNNER_TRAY_PILL_MANAGER_H_

#include <windows.h>

#include <functional>
#include <string>

#include "overlay_window.h"
#include "png_sequence.h"

namespace keti {

// Windows equivalent of the macOS TrayPillManager.
// Maintains a system tray icon and shows a dropped-card overlay underneath it
// that plays a PNG sequence.
class TrayPillManager {
 public:
  using DismissCallback = std::function<void()>;

  TrayPillManager();
  ~TrayPillManager();

  // Disable copy.
  TrayPillManager(const TrayPillManager&) = delete;
  TrayPillManager& operator=(const TrayPillManager&) = delete;

  // Initialize the tray icon. Must be called once before Show() and only after
  // the application has a valid top-level HWND.
  bool Setup(HINSTANCE instance, HWND message_hwnd);

  // Remove the tray icon.
  void Teardown();

  void Show(const std::wstring& assets_path,
            const std::wstring& resource_name,
            int width,
            int height,
            int frame_count,
            DismissCallback on_dismissed);

  void Dismiss();
  bool IsShowing() const;

  // Called by the owner window when a tray callback message arrives.
  void HandleTrayMessage(WPARAM wparam, LPARAM lparam);

 private:
  void AdvanceFrame();
  void PositionCardUnderTray();
  void OnDismiss();

  HINSTANCE instance_;
  HWND message_hwnd_;
  HICON tray_icon_;
  UINT tray_callback_message_;
  bool tray_icon_added_;

  OverlayWindow card_window_;
  PngSequence sequence_;
  int current_frame_;
  UINT_PTR timer_id_;
  bool has_finished_;
  DismissCallback on_dismissed_;

  static constexpr UINT kTrayIconId = 1;
  static constexpr UINT kFrameTimerId = 4;
  static constexpr UINT kFrameIntervalMs = 33;  // ~30 fps
};

}  // namespace keti

#endif  // RUNNER_TRAY_PILL_MANAGER_H_
