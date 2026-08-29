#include "flutter_window.h"

#include <optional>
#include <sstream>

#include "flutter/generated_plugin_registrant.h"

namespace {

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

constexpr char kChannelNotchHook[] = "app.keti/notch_hook";
constexpr char kChannelCursorPill[] = "app.keti/cursor_pill";
constexpr char kChannelTrayPill[] = "app.keti/tray_pill";
constexpr char kChannelComplianceCard[] = "app.keti/compliance_card";
constexpr char kChannelSessionLifecycle[] = "app.keti/session_lifecycle";

constexpr char kMethodShowIsland[] = "showIsland";
constexpr char kMethodShowCursorPill[] = "showPill";
constexpr char kMethodShowTrayPill[] = "showPill";
constexpr char kMethodShowComplianceCard[] = "showComplianceCard";
constexpr char kMethodSetSessionActive[] = "setSessionActive";
constexpr char kMethodCloseWindow[] = "closeWindow";
constexpr char kMethodOnShown[] = "onShown";
constexpr char kMethodOnHidden[] = "onHidden";
constexpr char kMethodOnCardAction[] = "onCardAction";
constexpr char kMethodOnCardTimeout[] = "onCardTimeout";

constexpr char kKeyResourceName[] = "resourceName";
constexpr char kKeyWidth[] = "width";
constexpr char kKeyHeight[] = "height";
constexpr char kKeyOffsetX[] = "offsetX";
constexpr char kKeyOffsetY[] = "offsetY";
constexpr char kKeyTotalFrames[] = "totalFrames";
constexpr char kKeyReminderId[] = "reminderId";
constexpr char kKeyTimeoutMs[] = "timeoutMs";
constexpr char kKeyQuestion[] = "question";
constexpr char kKeyButton1Text[] = "button1Text";
constexpr char kKeyButton2Text[] = "button2Text";
constexpr char kKeyAction[] = "action";

double GetDoubleValue(const flutter::EncodableMap* args, const char* key) {
  auto it = args->find(flutter::EncodableValue(key));
  if (it != args->end() && !it->second.IsNull()) {
    if (std::holds_alternative<double>(it->second)) {
      return std::get<double>(it->second);
    }
    if (std::holds_alternative<int32_t>(it->second)) {
      return static_cast<double>(std::get<int32_t>(it->second));
    }
    if (std::holds_alternative<int64_t>(it->second)) {
      return static_cast<double>(std::get<int64_t>(it->second));
    }
  }
  return 0.0;
}

std::string GetStringValue(const flutter::EncodableMap* args, const char* key) {
  auto it = args->find(flutter::EncodableValue(key));
  if (it != args->end() && !it->second.IsNull() &&
      std::holds_alternative<std::string>(it->second)) {
    return std::get<std::string>(it->second);
  }
  return std::string();
}

int GetIntValue(const flutter::EncodableMap* args, const char* key) {
  auto it = args->find(flutter::EncodableValue(key));
  if (it != args->end() && !it->second.IsNull()) {
    if (std::holds_alternative<int32_t>(it->second)) {
      return std::get<int32_t>(it->second);
    }
    if (std::holds_alternative<int64_t>(it->second)) {
      return static_cast<int>(std::get<int64_t>(it->second));
    }
    if (std::holds_alternative<double>(it->second)) {
      return static_cast<int>(std::get<double>(it->second));
    }
  }
  return 0;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  RegisterReminderChannels();
  tray_pill_manager_.Setup(GetModuleHandle(nullptr), GetHandle());

  return true;
}

void FlutterWindow::OnDestroy() {
  mouse_shake_detector_.Stop();
  island_manager_.Dismiss();
  cursor_pill_manager_.Dismiss();
  tray_pill_manager_.Teardown();
  compliance_card_manager_.Dismiss();

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_TIMER:
      if (wparam == keti::MouseShakeDetector::kTimerId) {
        mouse_shake_detector_.HandleTimer();
        return 0;
      }
      break;
  }

  if (message == tray_pill_manager_.tray_callback_message()) {
    tray_pill_manager_.HandleTrayMessage(wparam, lparam);
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::RegisterReminderChannels() {
  if (!flutter_controller_ || !flutter_controller_->engine()) {
    return;
  }

  auto* messenger = flutter_controller_->engine()->messenger();
  const auto& codec = flutter::StandardMethodCodec::GetInstance();

  notch_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, kChannelNotchHook, &codec);
  cursor_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, kChannelCursorPill, &codec);
  tray_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, kChannelTrayPill, &codec);
  compliance_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, kChannelComplianceCard, &codec);
  session_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, kChannelSessionLifecycle, &codec);

  HINSTANCE instance = GetModuleHandle(nullptr);
  std::wstring assets_path = GetAssetsPath();

  notch_channel_->SetMethodCallHandler(
      [this, instance, assets_path](const flutter::MethodCall<flutter::EncodableValue>& call,
                                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                                        result) {
        if (call.method_name() == kMethodShowIsland) {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args != nullptr) {
            std::string reminder_id = GetStringValue(args, kKeyReminderId);
            if (reminder_id.empty()) {
              reminder_id = "unknown";
            }
            std::wstring resource_name =
                Utf8ToWide(GetStringValue(args, kKeyResourceName));

            int width = static_cast<int>(GetDoubleValue(args, kKeyWidth));
            if (width <= 0) {
              width = 400;
            }
            int height = static_cast<int>(GetDoubleValue(args, kKeyHeight));
            if (height <= 0) {
              height = 100;
            }
            int total_frames = GetIntValue(args, kKeyTotalFrames);
            if (total_frames <= 0) {
              total_frames = 250;
            }
            // Render the notch card 50% larger than the configured size.
            width = static_cast<int>(width * 1.5);
            height = static_cast<int>(height * 1.5);

            island_manager_.Show(
                instance, assets_path, resource_name, width, height,
                total_frames,
                [this, reminder_id]() {
                  notch_channel_->InvokeMethod(
                      kMethodOnShown,
                      std::make_unique<flutter::EncodableValue>(reminder_id));
                },
                [this, reminder_id]() {
                  mouse_shake_detector_.Stop();
                  notch_channel_->InvokeMethod(
                      kMethodOnHidden,
                      std::make_unique<flutter::EncodableValue>(reminder_id));
                });
            if (island_manager_.IsShowing()) {
              mouse_shake_detector_.Start(GetHandle(), [this]() {
                island_manager_.Dismiss();
              });
            }
          }
          result->Success();
          return;
        }
        result->NotImplemented();
      });

  cursor_channel_->SetMethodCallHandler(
      [this, instance, assets_path](const flutter::MethodCall<flutter::EncodableValue>& call,
                                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                                        result) {
        if (call.method_name() == kMethodShowCursorPill) {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args != nullptr) {
            std::string reminder_id = GetStringValue(args, kKeyReminderId);
            if (reminder_id.empty()) {
              reminder_id = "unknown";
            }
            std::wstring resource_name =
                Utf8ToWide(GetStringValue(args, kKeyResourceName));

            int width = static_cast<int>(GetDoubleValue(args, kKeyWidth));
            if (width <= 0) {
              width = 150;
            }
            int height = static_cast<int>(GetDoubleValue(args, kKeyHeight));
            if (height <= 0) {
              height = 150;
            }
            // Cursor-pill size and position come from the resolver config. The
            // window is positioned by its top-left corner; offsetY = -height/2
            // vertically centers it on the cursor (Windows screen Y grows
            // downward, so the sign matches macOS).
            int offset_x = static_cast<int>(GetDoubleValue(args, kKeyOffsetX));
            int offset_y = static_cast<int>(GetDoubleValue(args, kKeyOffsetY));
            // Windows-only override: cursor pills render 50% larger than the
            // macOS baseline, with offsetY scaled by the same 1.5x to preserve
            // -height/2 centering. The gap differs by style: ambient doubles
            // its resolver gap (12 → 24), character gets a fixed 24px gap.
            const bool is_ambient = resource_name.rfind(L"ambient_", 0) == 0;
            const bool is_character =
                resource_name.rfind(L"character_", 0) == 0;
            if (is_ambient || is_character) {
              width = static_cast<int>(width * 1.5);
              height = static_cast<int>(height * 1.5);
              offset_y = static_cast<int>(offset_y * 1.5);
            }
            if (is_ambient) {
              offset_x *= 2;
            } else if (is_character) {
              offset_x = 24;
            }
            int total_frames = GetIntValue(args, kKeyTotalFrames);
            if (total_frames <= 0) {
              total_frames = 250;
            }

            cursor_pill_manager_.Show(
                instance, assets_path, resource_name, width, height, offset_x,
                offset_y, total_frames,
                [this, reminder_id]() {
                  cursor_channel_->InvokeMethod(
                      kMethodOnShown,
                      std::make_unique<flutter::EncodableValue>(reminder_id));
                },
                [this, reminder_id]() {
                  mouse_shake_detector_.Stop();
                  cursor_channel_->InvokeMethod(
                      kMethodOnHidden,
                      std::make_unique<flutter::EncodableValue>(reminder_id));
                });
            if (cursor_pill_manager_.IsShowing()) {
              mouse_shake_detector_.Start(GetHandle(), [this]() {
                cursor_pill_manager_.Dismiss();
              });
            }
          }
          result->Success();
          return;
        }
        result->NotImplemented();
      });

  tray_channel_->SetMethodCallHandler(
      [this, assets_path](const flutter::MethodCall<flutter::EncodableValue>& call,
                          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == kMethodShowTrayPill) {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args != nullptr) {
            std::string reminder_id = GetStringValue(args, kKeyReminderId);
            if (reminder_id.empty()) {
              reminder_id = "unknown";
            }
            std::wstring resource_name =
                Utf8ToWide(GetStringValue(args, kKeyResourceName));

            int width = static_cast<int>(GetDoubleValue(args, kKeyWidth));
            if (width <= 0) {
              width = 22;
            }
            int height = static_cast<int>(GetDoubleValue(args, kKeyHeight));
            if (height <= 0) {
              height = 22;
            }
            int total_frames = GetIntValue(args, kKeyTotalFrames);
            if (total_frames <= 0) {
              total_frames = 250;
            }

            tray_pill_manager_.Show(
                assets_path, resource_name, width, height, total_frames,
                [this, reminder_id]() {
                  tray_channel_->InvokeMethod(
                      kMethodOnShown,
                      std::make_unique<flutter::EncodableValue>(reminder_id));
                },
                [this, reminder_id]() {
                  mouse_shake_detector_.Stop();
                  tray_channel_->InvokeMethod(
                      kMethodOnHidden,
                      std::make_unique<flutter::EncodableValue>(reminder_id));
                });
            if (tray_pill_manager_.IsShowing()) {
              mouse_shake_detector_.Start(GetHandle(), [this]() {
                tray_pill_manager_.Dismiss();
              });
            }
          }
          result->Success();
          return;
        }
        result->NotImplemented();
      });

  compliance_channel_->SetMethodCallHandler(
      [this, instance](const flutter::MethodCall<flutter::EncodableValue>& call,
                       std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == kMethodShowComplianceCard) {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args != nullptr) {
            std::string reminder_id = GetStringValue(args, kKeyReminderId);
            if (reminder_id.empty()) {
              reminder_id = "unknown";
            }
            std::string question = GetStringValue(args, kKeyQuestion);
            if (question.empty()) {
              question = "Did you do it?";
            }
            std::string button1 = GetStringValue(args, kKeyButton1Text);
            if (button1.empty()) {
              button1 = "Done";
            }
            std::string button2 = GetStringValue(args, kKeyButton2Text);
            if (button2.empty()) {
              button2 = "Not now";
            }
            int timeout_ms = GetIntValue(args, kKeyTimeoutMs);
            if (timeout_ms <= 0) {
              timeout_ms = 120000;
            }

            compliance_card_manager_.Show(
                instance, GetHandle(), question, button1, button2, timeout_ms,
                [this, reminder_id](const std::string& action) {
                  flutter::EncodableMap outcome;
                  outcome[flutter::EncodableValue(kKeyReminderId)] =
                      flutter::EncodableValue(reminder_id);
                  outcome[flutter::EncodableValue(kKeyAction)] =
                      flutter::EncodableValue(action);
                  compliance_channel_->InvokeMethod(
                      kMethodOnCardAction,
                      std::make_unique<flutter::EncodableValue>(outcome));
                },
                [this, reminder_id]() {
                  compliance_channel_->InvokeMethod(
                      kMethodOnCardTimeout,
                      std::make_unique<flutter::EncodableValue>(reminder_id));
                });
          }
          result->Success();
          return;
        }
        result->NotImplemented();
      });

  session_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == kMethodSetSessionActive) {
          // Windows has no App Nap to suppress and the scheduler keeps running
          // while the message loop is alive, so this is an acknowledgment-only
          // no-op (macOS parity for the channel contract).
          result->Success();
          return;
        }
        if (call.method_name() == kMethodCloseWindow) {
          HWND hwnd = GetHandle();
          if (hwnd != nullptr) {
            PostMessage(hwnd, WM_CLOSE, 0, 0);
          }
          result->Success();
          return;
        }
        result->NotImplemented();
      });
}

std::wstring FlutterWindow::GetAssetsPath() const {
  wchar_t buffer[MAX_PATH];
  if (GetModuleFileNameW(nullptr, buffer, MAX_PATH) == 0) {
    return L"";
  }

  std::wstring path(buffer);
  size_t last_sep = path.find_last_of(L"\\/");
  if (last_sep == std::wstring::npos) {
    return L"";
  }

  std::wostringstream ss;
  ss << path.substr(0, last_sep)
     << L"\\data\\flutter_assets\\assets\\animations";
  return ss.str();
}
