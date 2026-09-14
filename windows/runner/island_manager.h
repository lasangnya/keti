#ifndef RUNNER_ISLAND_MANAGER_H_
#define RUNNER_ISLAND_MANAGER_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

#include "overlay_window.h"
#include "png_sequence.h"

namespace keti {

// Windows equivalent of the macOS IslandManager.
// Shows a top-center borderless overlay that plays a PNG sequence and can be
// dismissed by clicking anywhere on the overlay.
class IslandManager {
 public:
  using Callback = std::function<void()>;

  IslandManager();
  ~IslandManager();

  // Disable copy.
  IslandManager(const IslandManager&) = delete;
  IslandManager& operator=(const IslandManager&) = delete;

  // Shows the island and plays the PNG sequence once. |on_shown| fires after
  // the window is on screen; |on_hidden| fires exactly once when it is
  // dismissed (animation finished, mouse-shake, or a clobbering Show).
  void Show(HINSTANCE instance,
            const std::wstring& assets_path,
            const std::wstring& resource_name,
            int width,
            int height,
            int frame_count,
            Callback on_shown,
            Callback on_hidden);

  void Dismiss();
  bool IsShowing() const;

 private:
  void AdvanceFrame();
  void FireShown();
  void FireHidden();

  OverlayWindow window_;
  PngSequence sequence_;
  int current_frame_;
  UINT_PTR timer_id_;
  bool has_finished_;
  Callback on_shown_;
  Callback on_hidden_;

  static constexpr UINT kFrameTimerId = 1;
  static constexpr UINT kFrameIntervalMs = 33;  // ~30 fps
};

}  // namespace keti

#endif  // RUNNER_ISLAND_MANAGER_H_
