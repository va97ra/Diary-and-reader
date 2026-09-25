#ifndef RUNNER_LITERIA_MESSAGES_H_
#define RUNNER_LITERIA_MESSAGES_H_

#include <windows.h>

// The class of Literia's window. A second launch and the installer find the
// running app by it.
inline constexpr const wchar_t kLiteriaWindowClass[] = L"LITERIA_WINDOW";

// Asks the running Literia to show its window.
inline UINT LiteriaShowMessage() {
  static const UINT message = ::RegisterWindowMessageW(L"LiteriaShow");
  return message;
}

// Asks the running Literia to save its work and quit, as the installer does
// before it replaces the app's files.
inline UINT LiteriaQuitMessage() {
  static const UINT message = ::RegisterWindowMessageW(L"LiteriaQuit");
  return message;
}

#endif  // RUNNER_LITERIA_MESSAGES_H_
