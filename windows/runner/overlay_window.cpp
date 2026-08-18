#include "overlay_window.h"

#include <algorithm>
#include <cstring>

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

void OverlayWindow::SetMessageHandler(MessageHandler handler) {
  message_handler_ = std::move(handler);
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

  // UpdateLayeredWindow does not scale — it blits the top-left window-sized
  // region of the source bitmap. When a frame differs from the window size,
  // scale it into a window-sized, premultiplied-alpha bitmap first (aspect-fit,
  // centered), matching the macOS SwiftUI
  // `Image.resizable().aspectRatio(contentMode: .fit)`.
  HDC blit_dc = source_dc;
  HBITMAP scaled_bitmap = nullptr;
  HGDIOBJ old_scaled_bitmap = nullptr;

  if (source_width > 0 && source_height > 0 &&
      (source_width != width_ || source_height != height_)) {
    const double scale = (std::min)(
        static_cast<double>(width_) / source_width,
        static_cast<double>(height_) / source_height);
    const int fit_width =
        (std::max)(1, static_cast<int>(source_width * scale));
    const int fit_height =
        (std::max)(1, static_cast<int>(source_height * scale));
    const int fit_x = (width_ - fit_width) / 2;
    const int fit_y = (height_ - fit_height) / 2;

    BITMAPINFO bmi = {};
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = width_;
    bmi.bmiHeader.biHeight = -height_;  // top-down DIB
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;

    void* bits = nullptr;
    scaled_bitmap =
        CreateDIBSection(screen_dc, &bmi, DIB_RGB_COLORS, &bits, nullptr, 0);
    if (scaled_bitmap != nullptr) {
      blit_dc = CreateCompatibleDC(screen_dc);
      old_scaled_bitmap = SelectObject(blit_dc, scaled_bitmap);
      // Clear to fully transparent (premultiplied alpha = 0) so letterbox
      // borders don't show stale pixels.
      memset(bits, 0, static_cast<size_t>(width_) * height_ * 4);
      SetStretchBltMode(blit_dc, COLORONCOLOR);
      StretchBlt(blit_dc, fit_x, fit_y, fit_width, fit_height, source_dc, 0, 0,
                 source_width, source_height, SRCCOPY);
    }
  }

  SIZE dst_size = {width_, height_};
  POINT src_pos = {0, 0};
  BLENDFUNCTION blend = {};
  blend.BlendOp = AC_SRC_OVER;
  blend.SourceConstantAlpha = 255;
  blend.AlphaFormat = AC_SRC_ALPHA;

  // Passing nullptr for pptDst keeps the window at its current position.
  UpdateLayeredWindow(hwnd_, screen_dc, nullptr, &dst_size, blit_dc, &src_pos, 0,
                      &blend, ULW_ALPHA);

  if (scaled_bitmap != nullptr) {
    SelectObject(blit_dc, old_scaled_bitmap);
    DeleteObject(scaled_bitmap);
    DeleteDC(blit_dc);
  }
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

  auto* window = reinterpret_cast<OverlayWindow*>(
      GetWindowLongPtr(hwnd, GWLP_USERDATA));
  if (window != nullptr && window->message_handler_) {
    bool handled = window->message_handler_(hwnd, message, wparam, lparam);
    if (handled) {
      return 0;
    }
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}

}  // namespace keti
