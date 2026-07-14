#include "overlay_window.h"

#include <windowsx.h>

namespace keti {

namespace {

constexpr wchar_t kBaseClassName[] = L"KetiOverlayWindow";

int GenerateClassId() {
  static int counter = 0;
  return ++counter;
}

}  // namespace

OverlayWindow::OverlayWindow()
    : hwnd_(nullptr),
      instance_(nullptr),
      width_(0),
      height_(0),
      transparent_(false),
      topmost_(false) {}

OverlayWindow::~OverlayWindow() {
  Destroy();
}

bool OverlayWindow::Create(HINSTANCE instance,
                           const std::wstring& class_name,
                           int width,
                           int height,
                           bool layered,
                           bool transparent_for_mouse,
                           bool topmost,
                           bool tool_window,
                           bool no_activate) {
  if (hwnd_ != nullptr) {
    return true;
  }

  instance_ = instance;
  width_ = width;
  height_ = height;
  transparent_ = layered;
  topmost_ = topmost;

  // Generate a unique window class name so multiple overlays can coexist.
  std::wstring unique_class_name = class_name;
  if (unique_class_name.empty()) {
    unique_class_name = kBaseClassName;
  }
  unique_class_name += std::to_wstring(GenerateClassId());

  WNDCLASSEXW wc = {};
  wc.cbSize = sizeof(wc);
  wc.lpfnWndProc = WndProc;
  wc.hInstance = instance_;
  wc.lpszClassName = unique_class_name.c_str();
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  wc.hbrBackground = static_cast<HBRUSH>(GetStockObject(NULL_BRUSH));

  if (RegisterClassExW(&wc) == 0) {
    return false;
  }

  DWORD ex_style = 0;
  if (layered) {
    ex_style |= WS_EX_LAYERED;
  }
  if (transparent_for_mouse) {
    ex_style |= WS_EX_TRANSPARENT;
  }
  if (topmost) {
    ex_style |= WS_EX_TOPMOST;
  }
  if (tool_window) {
    ex_style |= WS_EX_TOOLWINDOW;
  }
  if (no_activate) {
    ex_style |= WS_EX_NOACTIVATE;
  }

  hwnd_ = CreateWindowExW(
      ex_style,
      unique_class_name.c_str(),
      L"",
      WS_POPUP,
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      width,
      height,
      nullptr,
      nullptr,
      instance_,
      this);

  if (hwnd_ == nullptr) {
    UnregisterClassW(unique_class_name.c_str(), instance_);
    return false;
  }

  return true;
}

void OverlayWindow::Destroy() {
  if (hwnd_ != nullptr) {
    DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }
}

void OverlayWindow::Show() {
  if (hwnd_ == nullptr) {
    return;
  }

  UINT flags = SWP_SHOWWINDOW | SWP_NOACTIVATE | SWP_FRAMECHANGED;
  if (!topmost_) {
    flags |= SWP_NOZORDER;
  }

  SetWindowPos(hwnd_, topmost_ ? HWND_TOPMOST : nullptr,
               0, 0, width_, height_, flags);
}

void OverlayWindow::Hide() {
  if (hwnd_ != nullptr) {
    ShowWindow(hwnd_, SW_HIDE);
  }
}

bool OverlayWindow::IsVisible() const {
  return hwnd_ != nullptr && IsWindowVisible(hwnd_);
}

void OverlayWindow::SetPosition(int x, int y) {
  if (hwnd_ == nullptr) {
    return;
  }
  SetWindowPos(hwnd_, nullptr, x, y, 0, 0,
               SWP_NOSIZE | SWP_NOACTIVATE | SWP_NOZORDER);
}

void OverlayWindow::SetSize(int width, int height) {
  if (hwnd_ == nullptr) {
    return;
  }
  width_ = width;
  height_ = height;
  SetWindowPos(hwnd_, nullptr, 0, 0, width, height,
               SWP_NOMOVE | SWP_NOACTIVATE | SWP_NOZORDER);
}

void OverlayWindow::UpdateLayeredContent(HDC source_dc,
                                         int source_width,
                                         int source_height) {
  if (hwnd_ == nullptr || source_dc == nullptr) {
    return;
  }
  if (!transparent_) {
    return;
  }

  HDC screen_dc = GetDC(nullptr);
  if (screen_dc == nullptr) {
    return;
  }

  POINT dst_pos = {0, 0};
  SIZE dst_size = {width_, height_};
  POINT src_pos = {0, 0};
  SIZE src_size = {source_width, source_height};

  BLENDFUNCTION blend = {};
  blend.BlendOp = AC_SRC_OVER;
  blend.SourceConstantAlpha = 255;
  blend.AlphaFormat = AC_SRC_ALPHA;

  // If the source bitmap is a different size than the window, scale via
  // StretchBlt into a temporary compatible DC first. For simplicity and to
  // match macOS behavior where content size equals window size, we assume
  // they match and call UpdateLayeredWindow directly.
  UpdateLayeredWindow(hwnd_, screen_dc, &dst_pos, &dst_size,
                      source_dc, &src_pos, 0, &blend, ULW_ALPHA);

  ReleaseDC(nullptr, screen_dc);
}

LRESULT CALLBACK OverlayWindow::WndProc(HWND hwnd,
                                        UINT message,
                                        WPARAM wparam,
                                        LPARAM lparam) {
  switch (message) {
    case WM_CREATE: {
      auto* cs = reinterpret_cast<CREATESTRUCT*>(lparam);
      auto* window = reinterpret_cast<OverlayWindow*>(cs->lpCreateParams);
      SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(window));
      return 0;
    }
    case WM_DESTROY: {
      auto* window = reinterpret_cast<OverlayWindow*>(
          GetWindowLongPtr(hwnd, GWLP_USERDATA));
      if (window != nullptr) {
        window->hwnd_ = nullptr;
      }
      return 0;
    }
    default:
      break;
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}

}  // namespace keti
