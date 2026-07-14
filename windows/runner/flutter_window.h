#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>

#include "cursor_pill_manager.h"
#include "island_manager.h"
#include "tray_pill_manager.h"
#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // Registers the method channel handlers for reminder overlays.
  void RegisterReminderChannels();

  // Builds the filesystem path used to locate PNG sequence assets.
  std::wstring GetAssetsPath() const;

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  // Method channels bridged to the Dart reminder services.
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> notch_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> cursor_channel_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> tray_channel_;

  // Native managers for each reminder presentation type.
  keti::IslandManager island_manager_;
  keti::CursorPillManager cursor_pill_manager_;
  keti::TrayPillManager tray_pill_manager_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
