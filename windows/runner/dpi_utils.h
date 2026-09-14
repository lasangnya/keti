#ifndef RUNNER_DPI_UTILS_H_
#define RUNNER_DPI_UTILS_H_

#include <windows.h>

namespace keti {

// All overlay dimensions are authored in logical units at this baseline (the
// same convention as macOS points). The runner is PerMonitorV2 DPI-aware, so
// Windows does not scale native windows for us: logical values must be
// converted to physical pixels for the monitor the overlay will appear on.
constexpr int kBaseDpi = 96;

// Converts a logical (96-DPI) value to physical pixels for |dpi|.
inline int ScaleForDpi(int logical, int dpi) {
  return MulDiv(logical, dpi, kBaseDpi);
}

// Returns the effective DPI of the monitor containing |point|. Falls back to
// 96 if the per-monitor API is unavailable.
int GetDpiForPoint(POINT point);

// Returns the effective DPI of the monitor |hwnd| is on. Prefers
// GetDpiForWindow (Windows 10 1607+), then the window's monitor. Falls back to
// 96 if neither is available.
int GetDpiForHwnd(HWND hwnd);

}  // namespace keti

#endif  // RUNNER_DPI_UTILS_H_
