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

constexpr char kMethodShowIsland[] = "showIsland";
constexpr char kMethodShowCursorPill[] = "showPill";
constexpr char kMethodShowTrayPill[] = "showPill";
constexpr char kMethodOnDismissed[] = "onDismissed";

constexpr char kKeyMessage[] = "message";
constexpr char kKeyResourceName[] = "resourceName";
constexpr char kKeyWidth[] = "width";
constexpr char kKeyHeight[] = "height";
constexpr char kKeyOffsetX[] = "offsetX";
constexpr char kKeyOffsetY[] = "offsetY";
constexpr char kKeyTotalFrames[] = "totalFrames";

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

}

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
  tray_pill_manager_.Teardown();

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

  HINSTANCE instance = GetModuleHandle(nullptr);
  std::wstring assets_path = GetAssetsPath();

  notch_channel_->SetMethodCallHandler(
      [this, instance, assets_path](const flutter::MethodCall<flutter::EncodableValue>& call,
                                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                                        result) {
        if (call.method_name() == kMethodShowIsland) {
          const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
          if (args != nullptr) {
            std::wstring resource_name;
            auto it = args->find(flutter::EncodableValue(kKeyResourceName));
            if (it != args->end()) {
              resource_name = Utf8ToWide(
                  std::get<std::string>(it->second));
            }

            int width = 400;
            int height = 100;
            int total_frames = 120;

            it = args->find(flutter::EncodableValue(kKeyWidth));
            if (it != args->end()) {
              width = static_cast<int>(GetDoubleValue(args, kKeyWidth));
            }
            it = args->find(flutter::EncodableValue(kKeyHeight));
            if (it != args->end()) {
              height = static_cast<int>(GetDoubleValue(args, kKeyHeight));
            }
            it = args->find(flutter::EncodableValue(kKeyTotalFrames));
            if (it != args->end()) {
              total_frames = static_cast<int>(GetDoubleValue(args, kKeyTotalFrames));
            }

            island_manager_.Show(
                instance, assets_path, resource_name, width, height,
                total_frames, [this]() {
                  notch_channel_->InvokeMethod(kMethodOnDismissed, nullptr);
                });
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
            std::wstring resource_name;
            auto it = args->find(flutter::EncodableValue(kKeyResourceName));
            if (it != args->end()) {
              resource_name = Utf8ToWide(
                  std::get<std::string>(it->second));
            }

            int width = 150;
            int height = 150;
            int offset_x = 0;
            int offset_y = 0;
            int total_frames = 120;

            it = args->find(flutter::EncodableValue(kKeyWidth));
            if (it != args->end()) {
              width = static_cast<int>(GetDoubleValue(args, kKeyWidth));
            }
            it = args->find(flutter::EncodableValue(kKeyHeight));
            if (it != args->end()) {
              height = static_cast<int>(GetDoubleValue(args, kKeyHeight));
            }
            it = args->find(flutter::EncodableValue(kKeyOffsetX));
            if (it != args->end()) {
              offset_x = static_cast<int>(GetDoubleValue(args, kKeyOffsetX));
            }
            it = args->find(flutter::EncodableValue(kKeyOffsetY));
            if (it != args->end()) {
              offset_y = static_cast<int>(GetDoubleValue(args, kKeyOffsetY));
            }
            it = args->find(flutter::EncodableValue(kKeyTotalFrames));
            if (it != args->end()) {
              total_frames = static_cast<int>(GetDoubleValue(args, kKeyTotalFrames));
            }

            cursor_pill_manager_.Show(
                instance, assets_path, resource_name, width, height, offset_x,
                offset_y, total_frames, [this]() {
                  cursor_channel_->InvokeMethod(kMethodOnDismissed, nullptr);
                });
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
            std::wstring resource_name;
            auto it = args->find(flutter::EncodableValue(kKeyResourceName));
            if (it != args->end()) {
              resource_name = Utf8ToWide(
                  std::get<std::string>(it->second));
            }

            int width = 22;
            int height = 22;
            int total_frames = 120;

            it = args->find(flutter::EncodableValue(kKeyWidth));
            if (it != args->end()) {
              width = static_cast<int>(GetDoubleValue(args, kKeyWidth));
            }
            it = args->find(flutter::EncodableValue(kKeyHeight));
            if (it != args->end()) {
              height = static_cast<int>(GetDoubleValue(args, kKeyHeight));
            }
            it = args->find(flutter::EncodableValue(kKeyTotalFrames));
            if (it != args->end()) {
              total_frames = static_cast<int>(GetDoubleValue(args, kKeyTotalFrames));
            }

            tray_pill_manager_.Show(
                assets_path, resource_name, width, height, total_frames,
                [this]() {
                  tray_channel_->InvokeMethod(kMethodOnDismissed, nullptr);
                });
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
