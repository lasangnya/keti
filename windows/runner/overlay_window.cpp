#include "overlay_window.h"

#include <algorithm>
#include <cstring>

#include <windowsx.h>

#pragma comment(lib, "msimg32.lib")  // AlphaBlend

namespace keti {

namespace {

constexpr wchar_t kBaseClassName[] = L"KetiOverlayWindow";

// Inset for the frame inside a rounded background so the animation doesn't
// touch the rounded corners.
constexpr int kBackgroundPadding = 8;

int GenerateClassId() {
  static int counter = 0;
  return ++counter;
}

// Fills a 32bpp premultiplied-alpha BGRA buffer with opaque black at |alpha|
// (RGB stays 0 since black premultiplies to 0).
void FillPremultipliedBlack(void* bits, int width, int height, BYTE alpha) {
  unsigned char* px = static_cast<unsigned char*>(bits);
  for (int i = 0; i < width * height; ++i) {
    px[0] = 0;      // B
    px[1] = 0;      // G
    px[2] = 0;      // R
    px[3] = alpha;  // A
    px += 4;
  }
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

  // SWP_NOMOVE | SWP_NOSIZE preserve the position chosen via SetPosition
  // (top-center for the island, cursor-relative for the cursor pill, top-right
  // for the tray pill) — without them this resets the window to (0, 0).
  UINT flags = SWP_SHOWWINDOW | SWP_NOACTIVATE | SWP_FRAMECHANGED | SWP_NOMOVE |
               SWP_NOSIZE;
  if (!topmost_) {
    flags |= SWP_NOZORDER;
  }

  SetWindowPos(hwnd_, topmost_ ? HWND_TOPMOST : nullptr, 0, 0, 0, 0, flags);
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

  const bool needs_scaling =
      source_width > 0 && source_height > 0 &&
      (source_width != width_ || source_height != height_);

  // Compose a window-sized bitmap whenever a pill background is requested or
  // the frame must be scaled (UpdateLayeredWindow does neither).
  HDC blit_dc = source_dc;
  HBITMAP composed_bitmap = nullptr;
  HGDIOBJ old_composed = nullptr;

  if (has_background_ || needs_scaling) {
    BITMAPINFO bmi = {};
    bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biWidth = width_;
    bmi.bmiHeader.biHeight = -height_;  // top-down DIB
    bmi.bmiHeader.biPlanes = 1;
    bmi.bmiHeader.biBitCount = 32;
    bmi.bmiHeader.biCompression = BI_RGB;

    void* bits = nullptr;
    composed_bitmap =
        CreateDIBSection(screen_dc, &bmi, DIB_RGB_COLORS, &bits, nullptr, 0);
    if (composed_bitmap != nullptr) {
      blit_dc = CreateCompatibleDC(screen_dc);
      old_composed = SelectObject(blit_dc, composed_bitmap);

      // Aspect-fit the frame, inset by the pill padding when a pill background
      // is drawn so the animation doesn't touch the rounded ends.
      int fit_width = width_;
      int fit_height = height_;
      int fit_x = 0;
      int fit_y = 0;
      if (source_width > 0 && source_height > 0) {
        const int avail_w =
            has_background_ ? width_ - 2 * kBackgroundPadding : width_;
        const int avail_h =
            has_background_ ? height_ - 2 * kBackgroundPadding : height_;
        const double scale = (std::min)(
            static_cast<double>(avail_w) / source_width,
            static_cast<double>(avail_h) / source_height);
        fit_width = (std::max)(1, static_cast<int>(source_width * scale));
        fit_height = (std::max)(1, static_cast<int>(source_height * scale));
        fit_x = (width_ - fit_width) / 2;
        fit_y = (height_ - fit_height) / 2;
      }

      if (has_background_) {
        // Semi-transparent black rounded background, then composite the frame
        // over it using per-pixel alpha (the frames are premultiplied, which
        // AC_SRC_OVER expects).
        FillPremultipliedBlack(bits, width_, height_, background_alpha_);
        BLENDFUNCTION blend = {AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};
        AlphaBlend(blit_dc, fit_x, fit_y, fit_width, fit_height, source_dc, 0,
                   0, source_width, source_height, blend);
      } else {
        // Transparent background + aspect-fit copy (letterboxed).
        memset(bits, 0, static_cast<size_t>(width_) * height_ * 4);
        SetStretchBltMode(blit_dc, COLORONCOLOR);
        StretchBlt(blit_dc, fit_x, fit_y, fit_width, fit_height, source_dc, 0, 0,
                   source_width, source_height, SRCCOPY);
      }
    }
  }

  SIZE dst_size = {width_, height_};
  POINT src_pos = {0, 0};
  BLENDFUNCTION blend = {AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};

  // Passing nullptr for pptDst keeps the window at its current position.
  UpdateLayeredWindow(hwnd_, screen_dc, nullptr, &dst_size, blit_dc, &src_pos, 0,
                      &blend, ULW_ALPHA);

  if (composed_bitmap != nullptr) {
    SelectObject(blit_dc, old_composed);
    DeleteObject(composed_bitmap);
    DeleteDC(blit_dc);
  }
  ReleaseDC(nullptr, screen_dc);
}

void OverlayWindow::SetRoundedBackground(int corner_diameter, BYTE alpha) {
  has_background_ = true;
  corner_diameter_ = corner_diameter;
  background_alpha_ = alpha;
  if (hwnd_ != nullptr) {
    // Clip the window to the rounded rect so the background has rounded
    // corners (a capsule uses corner_diameter == window height).
    HRGN region = CreateRoundRectRgn(0, 0, width_, height_, corner_diameter,
                                     corner_diameter);
    SetWindowRgn(hwnd_, region, TRUE);
  }
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
