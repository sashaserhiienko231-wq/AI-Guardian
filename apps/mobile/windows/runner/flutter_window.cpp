#include "flutter_window.h"

#include <tlhelp32.h>

#include <algorithm>
#include <cwctype>
#include <optional>
#include <string>
#include <utility>
#include <vector>

#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"
#include "utils.h"

namespace {

std::wstring GetEnvironmentValue(const wchar_t* name) {
  const DWORD length = GetEnvironmentVariableW(name, nullptr, 0);
  if (length == 0) {
    return {};
  }
  std::wstring value(length, L'\0');
  const DWORD copied = GetEnvironmentVariableW(name, value.data(), length);
  if (copied == 0 || copied >= length) {
    return {};
  }
  value.resize(copied);
  return value;
}

std::wstring NormalizePath(std::wstring path) {
  std::transform(path.begin(), path.end(), path.begin(),
                 [](wchar_t character) {
                   return static_cast<wchar_t>(std::towlower(character));
                 });
  while (path.size() > 3 && (path.back() == L'\\' || path.back() == L'/')) {
    path.pop_back();
  }
  return path;
}

bool IsWithinDirectory(const std::wstring& path, const std::wstring& root) {
  if (root.empty() || path.size() <= root.size() ||
      path.compare(0, root.size(), root) != 0) {
    return false;
  }
  return path[root.size()] == L'\\' || path[root.size()] == L'/';
}

std::optional<flutter::EncodableValue> ScanProcesses() {
  std::vector<std::wstring> roots = {
      NormalizePath(GetEnvironmentValue(L"TEMP")),
      NormalizePath(GetEnvironmentValue(L"TMP")),
  };
  const std::wstring profile = GetEnvironmentValue(L"USERPROFILE");
  if (!profile.empty()) {
    roots.push_back(NormalizePath(profile + L"\\Downloads"));
  }

  flutter::EncodableList findings;
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) {
    return std::nullopt;
  }

  PROCESSENTRY32W entry{};
  entry.dwSize = sizeof(entry);
  if (!Process32FirstW(snapshot, &entry)) {
    CloseHandle(snapshot);
    return std::nullopt;
  }

  int unreadable_processes = 0;
  do {
    if (entry.th32ProcessID == GetCurrentProcessId()) {
      continue;
    }

    HANDLE process =
        OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, entry.th32ProcessID);
    if (process == nullptr) {
      ++unreadable_processes;
      continue;
    }

    std::vector<wchar_t> image_path(32768);
    DWORD path_length = static_cast<DWORD>(image_path.size());
    const BOOL queried =
        QueryFullProcessImageNameW(process, 0, image_path.data(), &path_length);
    CloseHandle(process);
    if (!queried) {
      ++unreadable_processes;
      continue;
    }

    const std::wstring normalized_path =
        NormalizePath(std::wstring(image_path.data(), path_length));
    const bool writable_location = std::any_of(
        roots.begin(), roots.end(), [&normalized_path](const std::wstring& root) {
          return IsWithinDirectory(normalized_path, root);
        });
    if (!writable_location) {
      continue;
    }

    flutter::EncodableMap finding;
    finding[flutter::EncodableValue("pid")] =
        flutter::EncodableValue(static_cast<int32_t>(entry.th32ProcessID));
    finding[flutter::EncodableValue("name")] =
        flutter::EncodableValue(Utf8FromUtf16(entry.szExeFile));
    finding[flutter::EncodableValue("reason")] = flutter::EncodableValue(
        "Executable is running from a user-writable Temp or Downloads folder. "
        "This is a risk signal, not proof of malware.");
    findings.push_back(flutter::EncodableValue(std::move(finding)));
  } while (Process32NextW(snapshot, &entry));

  const DWORD enumeration_error = GetLastError();
  CloseHandle(snapshot);
  if (enumeration_error != ERROR_NO_MORE_FILES) {
    return std::nullopt;
  }

  flutter::EncodableMap report;
  report[flutter::EncodableValue("findings")] =
      flutter::EncodableValue(std::move(findings));
  report[flutter::EncodableValue("unreadable_processes")] =
      flutter::EncodableValue(unreadable_processes);
  return flutter::EncodableValue(std::move(report));
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
  process_scanner_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "ai_guardian/process_scanner",
          &flutter::StandardMethodCodec::GetInstance());
  process_scanner_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "scanProcesses") {
          auto scan = ScanProcesses();
          if (scan.has_value()) {
            result->Success(std::move(scan.value()));
          } else {
            result->Error("process_scan_failed",
                          "Windows could not enumerate running processes.");
          }
        } else {
          result->NotImplemented();
        }
      });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
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

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
