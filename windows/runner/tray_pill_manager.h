#ifndef RUNNER_TRAY_PILL_MANAGER_H_
#define RUNNER_TRAY_PILL_MANAGER_H_

#include <windows.h>

#include <functional>
#include <string>

#include "overlay_window.h"
#include "png_sequence.h"

namespace keti {

// Windows equivalent of the macOS TrayPillManager.
// Maintains a system tray icon and shows a top-right pill overlay that plays a
// PNG sequence (positioned to match the macOS menu bar, for study consistency).
class TrayPillManager {
 public:
  using Callback = std::function<void()>;

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

  // Shows the dropped-card overlay and plays the PNG sequence once.
  // |on_shown| fires after the card is on screen; |on_hidden| fires exactly
  // once when it is dismissed (animation finished, mouse-shake, or a
  // clobbering Show).
  void Show(const std::wstring& assets_path,
            const std::wstring& resource_name,
            int width,
            int height,
            int frame_count,
            Callback on_shown,
            Callback on_hidden);

  void Dismiss();
  bool IsShowing() const;

  // Called by the owner window when a tray callback message arrives.
  void HandleTrayMessage(WPARAM wparam, LPARAM lparam);

  // The registered tray callback message identifier.
  UINT tray_callback_message() const { return tray_callback_message_; }

 private:
  void AdvanceFrame();
  void PositionCardTopRight();
  void FireShown();
  void FireHidden();

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
  Callback on_shown_;
  Callback on_hidden_;

  static constexpr UINT kTrayIconId = 1;
  static constexpr UINT kFrameTimerId = 4;
  static constexpr UINT kFrameIntervalMs = 33;  // ~30 fps
};

}  // namespace keti

#endif  // RUNNER_TRAY_PILL_MANAGER_H_
