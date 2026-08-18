#include "compliance_card_manager.h"

#include <windowsx.h>

namespace keti {

namespace {

constexpr wchar_t kWindowClassName[] = L"KetiComplianceCard";

// Logical layout (points at 96 DPI), scaled to the monitor DPI at runtime.
constexpr int kLogicalPadding = 24;
constexpr int kLogicalButtonWidth = 120;
constexpr int kLogicalButtonHeight = 44;
constexpr int kLogicalButtonSpacing = 12;
constexpr int kLogicalQuestionGap = 16;
constexpr int kLogicalCornerRadius = 20;
constexpr int kLogicalButtonCornerRadius = 10;
constexpr int kLogicalEdgeMargin = 28;
constexpr int kLogicalMaxCardWidth = 420;

// Palette mirrors the macOS ComplianceCardView (black @ 0.9 over a white
// button / white question text).
constexpr COLORREF kBackgroundColor = RGB(26, 26, 26);
constexpr COLORREF kBorderColor = RGB(70, 70, 70);
constexpr COLORREF kQuestionTextColor = RGB(255, 255, 255);
constexpr COLORREF kButtonFillColor = RGB(255, 255, 255);
constexpr COLORREF kButtonTextColor = RGB(0, 0, 0);

int ScalePx(int logical, int dpi) {
  return MulDiv(logical, dpi, 96);
}

std::wstring Utf8ToWide(const std::string& utf8) {
  if (utf8.empty()) {
    return std::wstring();
  }
  int size = MultiByteToWideChar(CP_UTF8, 0, utf8.data(),
                                 static_cast<int>(utf8.size()), nullptr, 0);
  if (size <= 0) {
    return std::wstring();
  }
  std::wstring wide(size, 0);
  MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                      wide.data(), size);
  return wide;
}

HFONT CreatePointFont(int point_size, int weight, int dpi) {
  return CreateFontW(-MulDiv(point_size, dpi, 72), 0, 0, 0, weight, FALSE,
                     FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
                     CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                     DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
}

}  // namespace

ComplianceCardManager::ComplianceCardManager() = default;

ComplianceCardManager::~ComplianceCardManager() {
  on_action_ = nullptr;
  on_timeout_ = nullptr;
  Dismiss();
}

void ComplianceCardManager::Show(HINSTANCE instance,
                                 HWND owner,
                                 const std::string& question,
                                 const std::string& button1_text,
                                 const std::string& button2_text,
                                 int timeout_ms,
                                 ActionCallback on_action,
                                 TimeoutCallback on_timeout) {
  Dismiss();

  question_ = Utf8ToWide(question);
  button1_text_ = Utf8ToWide(button1_text);
  button2_text_ = Utf8ToWide(button2_text);
  on_action_ = std::move(on_action);
  on_timeout_ = std::move(on_timeout);
  instance_ = instance;

  int dpi = 96;
  HDC dpi_dc = GetDC(owner);
  if (dpi_dc != nullptr) {
    int measured = GetDeviceCaps(dpi_dc, LOGPIXELSX);
    if (measured > 0) {
      dpi = measured;
    }
    ReleaseDC(owner, dpi_dc);
  }

  ComputeLayout(dpi);

  // Register the window class once per process.
  static bool class_registered = false;
  if (!class_registered) {
    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = instance_;
    wc.lpszClassName = kWindowClassName;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = nullptr;
    RegisterClassExW(&wc);
    class_registered = true;
  }

  // The card has no non-client area; its size equals the layout size. The
  // question rect spans the full content width and the button row is the
  // bottom-most element, so their edges define the card bounds.
  const int pad = ScalePx(kLogicalPadding, dpi);
  int card_width = question_rect_.right + pad;
  int card_height = button1_rect_.bottom + pad;

  HWND hwnd = CreateWindowExW(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE, kWindowClassName,
      L"", WS_POPUP, 0, 0, card_width, card_height, nullptr, nullptr,
      instance_, this);
  if (hwnd == nullptr) {
    DeleteFonts();
    on_action_ = nullptr;
    on_timeout_ = nullptr;
    return;
  }
  hwnd_ = hwnd;

  // Rounded corners via a window region.
  HRGN region =
      CreateRoundRectRgn(0, 0, card_width + 1, card_height + 1,
                         corner_radius_, corner_radius_);
  SetWindowRgn(hwnd_, region, TRUE);

  // Anchor to the top-right corner of the monitor the app is on (matches the
  // macOS edge margin of 28 points).
  MONITORINFO mi = {};
  mi.cbSize = sizeof(mi);
  HMONITOR monitor =
      owner != nullptr ? MonitorFromWindow(owner, MONITOR_DEFAULTTONEAREST)
                       : MonitorFromPoint(POINT{0, 0}, MONITOR_DEFAULTTOPRIMARY);
  GetMonitorInfoW(monitor, &mi);

  int margin = ScalePx(kLogicalEdgeMargin, dpi);
  int x = mi.rcWork.right - card_width - margin;
  int y = mi.rcWork.top + margin;
  SetWindowPos(hwnd_, nullptr, x, y, 0, 0,
               SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);

  ShowWindow(hwnd_, SW_SHOWNOACTIVATE);

  if (timeout_ms < 1) {
    timeout_ms = 1;
  }
  timeout_timer_id_ =
      SetTimer(hwnd_, kTimeoutTimerId, static_cast<UINT>(timeout_ms), nullptr);
}

void ComplianceCardManager::Dismiss() {
  if (timeout_timer_id_ != 0) {
    KillTimer(hwnd_, timeout_timer_id_);
    timeout_timer_id_ = 0;
  }
  if (hwnd_ != nullptr) {
    DestroyWindow(hwnd_);
    hwnd_ = nullptr;
  }
  DeleteFonts();
  on_action_ = nullptr;
  on_timeout_ = nullptr;
}

bool ComplianceCardManager::IsShowing() const {
  return hwnd_ != nullptr && IsWindowVisible(hwnd_);
}

void ComplianceCardManager::ComputeLayout(int dpi) {
  const int pad = ScalePx(kLogicalPadding, dpi);
  const int btn_w = ScalePx(kLogicalButtonWidth, dpi);
  const int btn_h = ScalePx(kLogicalButtonHeight, dpi);
  const int btn_spacing = ScalePx(kLogicalButtonSpacing, dpi);
  const int gap = ScalePx(kLogicalQuestionGap, dpi);
  corner_radius_ = ScalePx(kLogicalCornerRadius, dpi);
  button_corner_radius_ = ScalePx(kLogicalButtonCornerRadius, dpi);

  question_font_ = CreatePointFont(17, FW_SEMIBOLD, dpi);
  button_font_ = CreatePointFont(15, FW_BOLD, dpi);

  const int max_question_width =
      ScalePx(kLogicalMaxCardWidth, dpi) - 2 * pad;

  // Measure the question text (may wrap to a second line).
  RECT measure = {0, 0, max_question_width, 0};
  HDC measure_dc = GetDC(nullptr);
  HGDIOBJ old_font = SelectObject(measure_dc, question_font_);
  DrawTextW(measure_dc, question_.c_str(), -1, &measure,
            DT_CALCRECT | DT_WORDBREAK | DT_CENTER);
  SelectObject(measure_dc, old_font);
  ReleaseDC(nullptr, measure_dc);

  int question_w = measure.right - measure.left;
  int question_h = measure.bottom - measure.top;

  const int buttons_row_w = 2 * btn_w + btn_spacing;
  const int content_w = (question_w > buttons_row_w) ? question_w : buttons_row_w;

  const int btn_y = pad + question_h + gap;
  const int btn_x = pad + (content_w - buttons_row_w) / 2;

  question_rect_ = {pad, pad, pad + content_w, pad + question_h};
  button1_rect_ = {btn_x, btn_y, btn_x + btn_w, btn_y + btn_h};
  button2_rect_ = {btn_x + btn_w + btn_spacing, btn_y,
                   btn_x + btn_w + btn_spacing + btn_w, btn_y + btn_h};
}

void ComplianceCardManager::DeleteFonts() {
  if (question_font_ != nullptr) {
    DeleteObject(question_font_);
    question_font_ = nullptr;
  }
  if (button_font_ != nullptr) {
    DeleteObject(button_font_);
    button_font_ = nullptr;
  }
}

void ComplianceCardManager::Paint(HDC hdc) {
  RECT rc = {};
  GetClientRect(hwnd_, &rc);
  int width = rc.right - rc.left;
  int height = rc.bottom - rc.top;

  HDC mem = CreateCompatibleDC(hdc);
  HBITMAP bitmap = CreateCompatibleBitmap(hdc, width, height);
  HGDIOBJ old_bitmap = SelectObject(mem, bitmap);

  // Background.
  HBRUSH background = CreateSolidBrush(kBackgroundColor);
  FillRect(mem, &rc, background);
  DeleteObject(background);

  // Subtle border, clipped to the rounded region.
  HPEN border_pen = CreatePen(PS_SOLID, 1, kBorderColor);
  HGDIOBJ old_pen = SelectObject(mem, border_pen);
  HGDIOBJ old_brush = SelectObject(mem, GetStockObject(NULL_BRUSH));
  RoundRect(mem, 0, 0, width, height, corner_radius_, corner_radius_);
  SelectObject(mem, old_pen);
  SelectObject(mem, old_brush);
  DeleteObject(border_pen);

  // Question text.
  SetBkMode(mem, TRANSPARENT);
  SetTextColor(mem, kQuestionTextColor);
  HGDIOBJ old_font = SelectObject(mem, question_font_);
  DrawTextW(mem, question_.c_str(), -1, &question_rect_,
            DT_CENTER | DT_WORDBREAK);
  SelectObject(mem, old_font);

  // Outcome buttons.
  DrawButton(mem, button1_rect_, button1_text_);
  DrawButton(mem, button2_rect_, button2_text_);

  BitBlt(hdc, 0, 0, width, height, mem, 0, 0, SRCCOPY);
  SelectObject(mem, old_bitmap);
  DeleteObject(bitmap);
  DeleteDC(mem);
}

void ComplianceCardManager::DrawButton(HDC hdc,
                                       const RECT& rect,
                                       const std::wstring& text) {
  HPEN pen = CreatePen(PS_SOLID, 1, kButtonFillColor);
  HBRUSH brush = CreateSolidBrush(kButtonFillColor);
  HGDIOBJ old_pen = SelectObject(hdc, pen);
  HGDIOBJ old_brush = SelectObject(hdc, brush);
  RoundRect(hdc, rect.left, rect.top, rect.right, rect.bottom,
            button_corner_radius_, button_corner_radius_);
  SelectObject(hdc, old_pen);
  SelectObject(hdc, old_brush);
  DeleteObject(pen);
  DeleteObject(brush);

  SetBkMode(hdc, TRANSPARENT);
  SetTextColor(hdc, kButtonTextColor);
  RECT text_rect = rect;
  HGDIOBJ old_font = SelectObject(hdc, button_font_);
  DrawTextW(hdc, text.c_str(), -1, &text_rect, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
  SelectObject(hdc, old_font);
}

void ComplianceCardManager::HandleClick(int x, int y) {
  POINT pt = {x, y};
  if (PtInRect(&button1_rect_, pt)) {
    OnAction("completed");
  } else if (PtInRect(&button2_rect_, pt)) {
    OnAction("dismissed");
  }
}

void ComplianceCardManager::OnAction(const std::string& action) {
  auto callback = std::move(on_action_);
  Dismiss();
  if (callback) {
    callback(action);
  }
}

void ComplianceCardManager::OnTimeout() {
  auto callback = std::move(on_timeout_);
  Dismiss();
  if (callback) {
    callback();
  }
}

LRESULT CALLBACK ComplianceCardManager::WndProc(HWND hwnd,
                                                UINT message,
                                                WPARAM wparam,
                                                LPARAM lparam) {
  switch (message) {
    case WM_CREATE: {
      auto* create_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
      SetWindowLongPtr(hwnd, GWLP_USERDATA,
                       reinterpret_cast<LONG_PTR>(create_struct->lpCreateParams));
      return 0;
    }
    case WM_PAINT: {
      auto* window = reinterpret_cast<ComplianceCardManager*>(
          GetWindowLongPtr(hwnd, GWLP_USERDATA));
      if (window != nullptr) {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        window->Paint(hdc);
        EndPaint(hwnd, &ps);
      }
      return 0;
    }
    case WM_ERASEBKGND:
      return 1;  // Fully painted in WM_PAINT to avoid flicker.
    case WM_TIMER: {
      auto* window = reinterpret_cast<ComplianceCardManager*>(
          GetWindowLongPtr(hwnd, GWLP_USERDATA));
      if (window != nullptr && wparam == kTimeoutTimerId) {
        window->OnTimeout();
      }
      return 0;
    }
    case WM_LBUTTONUP: {
      auto* window = reinterpret_cast<ComplianceCardManager*>(
          GetWindowLongPtr(hwnd, GWLP_USERDATA));
      if (window != nullptr) {
        window->HandleClick(GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam));
      }
      return 0;
    }
    case WM_DESTROY: {
      auto* window = reinterpret_cast<ComplianceCardManager*>(
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
