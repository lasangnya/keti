#ifndef RUNNER_OVERLAY_WINDOW_H_
#define RUNNER_OVERLAY_WINDOW_H_

#include <windows.h>

#include <string>

namespace keti {

// A borderless, layered, topmost Win32 window used to display animated
// PNG reminders. Matches the behavior of the macOS NSPanel overlays.
class OverlayWindow {
 public:
  OverlayWindow();
  ~OverlayWindow();

  // Disable copy.
  OverlayWindow(const OverlayWindow&) = delete;
  OverlayWindow& operator=(const OverlayWindow&) = delete;

  // Creates the window. Returns true on success.
  bool Create(HINSTANCE instance,
              const std::wstring& class_name,
              int width,
              int height,
              bool transparent,
              bool topmost,
              bool tool_window,
              bool no_activate);

  void Destroy();

  bool IsCreated() const { return hwnd_ != nullptr; }
  HWND handle() const { return hwnd_; }

  void Show();
  void Hide();
  bool IsVisible() const;

  void SetPosition(int x, int y);
  void SetSize(int width, int height);

  // Update the visible content with a 32bpp premultiplied-alpha BGRA bitmap
  // from the given source. The source bitmap must remain valid for the call.
  void UpdateLayeredContent(HDC source_dc,
                            int source_width,
                            int source_height);

 private:
  static LRESULT CALLBACK WndProc(HWND hwnd,
                                  UINT message,
                                  WPARAM wparam,
                                  LPARAM lparam);

  HWND hwnd_;
  HINSTANCE instance_;
  int width_;
  int height_;
  bool transparent_;
  bool topmost_;
};

}  // namespace keti

#endif  // RUNNER_OVERLAY_WINDOW_H_
