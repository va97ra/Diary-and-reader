#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>

#include "flutter_window.h"
#include "literia_messages.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();
  const bool start_in_tray =
      std::find(command_line_arguments.begin(), command_line_arguments.end(),
                "--tray") != command_line_arguments.end();

  // One Literia at a time. Opening it again shows the running one, while a
  // second start with Windows simply leaves it in the tray.
  ::CreateMutexW(nullptr, TRUE, L"Local\\LiteriaSingleInstance");
  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND running = ::FindWindowW(kLiteriaWindowClass, nullptr);
    if (running && !start_in_tray) {
      ::AllowSetForegroundWindow(ASFW_ANY);
      ::PostMessageW(running, LiteriaShowMessage(), 0, 0);
    }
    return EXIT_SUCCESS;
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project, start_in_tray);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"\u041b\u0438\u0442\u0435\u0440\u0438\u044f", origin,
                     size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
