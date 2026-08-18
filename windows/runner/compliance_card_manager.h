#ifndef RUNNER_COMPLIANCE_CARD_MANAGER_H_
#define RUNNER_COMPLIANCE_CARD_MANAGER_H_

#include <windows.h>

#include <functional>
#include <string>

namespace keti {

// Windows equivalent of the macOS ComplianceCardManager (plan §5.4): a small
// borderless, topmost, non-activating card at the top-right corner of the
// screen with a question and two outcome buttons. Position, sizing and
// behavior are identical for every reminder — it is the constant measurement
// instrument of the study.
//
// Button 1 reports "completed", button 2 reports "dismissed" via
// |on_action|; after |timeout_ms| without a click, |on_timeout| fires. Exactly
// one of the two callbacks fires per shown card.
class ComplianceCardManager {
 public:
  using ActionCallback = std::function<void(const std::string& action)>;
  using TimeoutCallback = std::function<void()>;

  ComplianceCardManager();
  ~ComplianceCardManager();

  // Disable copy.
  ComplianceCardManager(const ComplianceCardManager&) = delete;
  ComplianceCardManager& operator=(const ComplianceCardManager&) = delete;

  // Shows the card. |owner| is the main window handle, used to anchor the card
  // to the monitor the app is displayed on. |question|, |button1_text| and
  // |button2_text| are UTF-8.
  void Show(HINSTANCE instance,
            HWND owner,
            const std::string& question,
            const std::string& button1_text,
            const std::string& button2_text,
            int timeout_ms,
            ActionCallback on_action,
            TimeoutCallback on_timeout);

  // Removes the card without firing either callback.
  void Dismiss();
  bool IsShowing() const;

 private:
  static LRESULT CALLBACK WndProc(HWND hwnd, UINT message, WPARAM wparam,
                                  LPARAM lparam);

  void Paint(HDC hdc);
  void DrawButton(HDC hdc, const RECT& rect, const std::wstring& text);
  void HandleClick(int x, int y);
  void OnAction(const std::string& action);
  void OnTimeout();
  void DeleteFonts();
  void ComputeLayout(int dpi);

  HWND hwnd_ = nullptr;
  HINSTANCE instance_ = nullptr;

  std::wstring question_;
  std::wstring button1_text_;
  std::wstring button2_text_;

  ActionCallback on_action_;
  TimeoutCallback on_timeout_;

  UINT_PTR timeout_timer_id_ = 0;

  HFONT question_font_ = nullptr;
  HFONT button_font_ = nullptr;

  // Layout metrics in device pixels (DPI-scaled from logical points).
  int corner_radius_ = 0;
  int button_corner_radius_ = 0;
  RECT question_rect_ = {};
  RECT button1_rect_ = {};
  RECT button2_rect_ = {};

  static constexpr UINT kTimeoutTimerId = 20;
};

}  // namespace keti

#endif  // RUNNER_COMPLIANCE_CARD_MANAGER_H_
