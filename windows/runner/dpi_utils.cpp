#include "dpi_utils.h"

namespace keti {

namespace {

// Calls GetDpiForMonitor (Shcore.dll, Windows 8.1+) for |monitor|. Returns 0
// when the API is unavailable or fails.
int GetDpiForMonitorHandle(HMONITOR monitor) {
  if (monitor == nullptr) {
    return 0;
  }

  HMODULE shcore = LoadLibraryW(L"Shcore.dll");
  if (shcore == nullptr) {
    return 0;
  }

  using GetDpiForMonitorFn = HRESULT(WINAPI*)(HMONITOR, int, UINT*, UINT*);
  auto get_dpi = reinterpret_cast<GetDpiForMonitorFn>(
      GetProcAddress(shcore, "GetDpiForMonitor"));

  int dpi = 0;
  if (get_dpi != nullptr) {
    UINT dpi_x = 0;
    UINT dpi_y = 0;
    // 0 == MDT_EFFECTIVE_DPI (the DPI the user sees, accounting for scaling).
    if (SUCCEEDED(get_dpi(monitor, 0, &dpi_x, &dpi_y))) {
      dpi = static_cast<int>(dpi_x);
    }
  }

  FreeLibrary(shcore);
  return dpi;
}

}  // namespace

int GetDpiForPoint(POINT point) {
  HMONITOR monitor = MonitorFromPoint(point, MONITOR_DEFAULTTONEAREST);
  int dpi = GetDpiForMonitorHandle(monitor);
  return dpi > 0 ? dpi : kBaseDpi;
}

int GetDpiForHwnd(HWND hwnd) {
  if (hwnd != nullptr) {
    HMODULE user32 = GetModuleHandleW(L"user32.dll");
    if (user32 != nullptr) {
      using GetDpiForWindowFn = UINT(WINAPI*)(HWND);
      auto get_dpi = reinterpret_cast<GetDpiForWindowFn>(
          GetProcAddress(user32, "GetDpiForWindow"));
      if (get_dpi != nullptr) {
        UINT dpi = get_dpi(hwnd);
        if (dpi > 0) {
          return static_cast<int>(dpi);
        }
      }
    }

    // GetDpiForWindow is Windows 10 1607+; fall back to the window's monitor
    // so a downgraded OS still scales correctly.
    int dpi =
        GetDpiForMonitorHandle(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST));
    if (dpi > 0) {
      return dpi;
    }
  }
  return kBaseDpi;
}

}  // namespace keti
