import 'package:flutter/foundation.dart';

export 'literia_desktop_shell_stub.dart'
    if (dart.library.io) 'literia_desktop_shell_io.dart';

/// How the desktop window shows itself.
enum LiteriaWindowMode {
  /// A compact panel beside the clock, like the Windows calendar.
  panel,

  /// An ordinary window with a title bar and a taskbar button.
  window,
}

/// The tray icon and the panel beside the clock that Literia has on Windows.
/// Closing the window hides it in the tray; only "Quit" ends the app.
abstract class LiteriaDesktopShell {
  ValueListenable<LiteriaWindowMode> get mode;

  Future<void> showPanel();

  Future<void> showWindow();

  /// Hides the window; the app keeps running in the tray.
  Future<void> hide();

  /// Saves the work and ends the app, tray icon included.
  Future<void> quit();

  /// Re-labels the tray menu after the interface language changed.
  Future<void> updateLanguage(String languageCode);
}
