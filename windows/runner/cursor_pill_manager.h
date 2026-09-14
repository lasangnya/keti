#ifndef RUNNER_CURSOR_PILL_MANAGER_H_
#define RUNNER_CURSOR_PILL_MANAGER_H_

#include <windows.h>

#include <functional>
#include <string>

#include "overlay_window.h"
#include "png_sequence.h"

namespace keti {

// Windows equivalent of the macOS CursorPillManager.
// Shows a small borderless overlay that follows the mouse cursor and plays a
// PNG sequence. The overlay ignores mouse events so it does not interfere with
// the user's work.
class CursorPillManager {
 public:
  using Callback = std::function<void()>;

  CursorPillManager();
  ~CursorPillManager();

  // Disable copy.
  CursorPillManager(const CursorPillManager&) = delete;
  CursorPillManager& operator=(const CursorPillManager&) = delete;

  // Shows the pill and plays the PNG sequence once, following the cursor.
  // |on_shown| fires after the window is on screen; |on_hidden| fires exactly
  // once when it is dismissed (animation finished, mouse-shake, or a
  // clobbering Show).
  void Show(HINSTANCE instance,
            const std::wstring& assets_path,
            const std::wstring& resource_name,
            int width,
            int height,
            int offset_x,
            int offset_y,
            int frame_count,
            Callback on_shown,
            Callback on_hidden);

  void Dismiss();
  bool IsShowing() const;

 private:
  void AdvanceFrame();
  void UpdateCursorPosition();
  void FireShown();
  void FireHidden();

  OverlayWindow window_;
  PngSequence sequence_;
  int current_frame_;
  int offset_x_;
  int offset_y_;
  UINT_PTR frame_timer_id_;
  UINT_PTR cursor_timer_id_;
  bool has_finished_;
  Callback on_shown_;
  Callback on_hidden_;

  static constexpr UINT kFrameTimerId = 2;
  static constexpr UINT kCursorTimerId = 3;
  static constexpr UINT kFrameIntervalMs = 33;    // ~30 fps
  static constexpr UINT kCursorIntervalMs = 16;   // ~60 fps
};

}  // namespace keti

#endif  // RUNNER_CURSOR_PILL_MANAGER_H_
