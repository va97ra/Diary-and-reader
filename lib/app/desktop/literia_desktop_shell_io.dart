import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dnevnik/app/desktop/literia_desktop_shell.dart';
import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Starts the tray and window handling on Windows; elsewhere there is none.
/// With `--tray`, as when Windows starts the app, only the tray icon shows.
Future<LiteriaDesktopShell?> startLiteriaDesktopShell({
  required List<String> arguments,
  required String languageCode,
  required Future<void> Function() beforeQuit,
}) async {
  if (!Platform.isWindows) return null;
  final shell = _WindowsDesktopShell(beforeQuit);
  await shell._start(
    languageCode: languageCode,
    startInTray: arguments.contains('--tray'),
  );
  return shell;
}

class _WindowsDesktopShell
    with TrayListener, WindowListener
    implements LiteriaDesktopShell {
  _WindowsDesktopShell(this._beforeQuit);

  static const _channel = MethodChannel('literia/desktop');
  static const _panelWidth = 420.0;
  static const _panelHeight = 760.0;
  static const _screenMargin = 12.0;

  final Future<void> Function() _beforeQuit;
  final _mode = ValueNotifier(LiteriaWindowMode.window);
  Rect? _windowBounds;
  bool _windowMaximized = false;
  bool _quitting = false;

  @override
  ValueListenable<LiteriaWindowMode> get mode => _mode;

  Future<void> _start({
    required String languageCode,
    required bool startInTray,
  }) async {
    await windowManager.ensureInitialized();
    // Also prepares the taskbar handle that setSkipTaskbar needs; without it
    // the plugin crashes the app.
    await windowManager.waitUntilReadyToShow();
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);
    trayManager.addListener(this);
    await trayManager.setIcon('assets/branding/tray_icon.ico');
    await updateLanguage(languageCode);
    if (startInTray) {
      // Opened from the tray at sign-in, the first click brings the panel.
      _mode.value = LiteriaWindowMode.panel;
    } else {
      // Placed before the first frame, when the window appears.
      await windowManager.setBounds(await _defaultWindowBounds());
    }
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        // Opened again from a shortcut: the full window, not the panel.
        case 'show':
          await showWindow();
        case 'quit':
          await quit();
      }
    });
  }

  @override
  Future<void> updateLanguage(String languageCode) async {
    final strings = AppStrings.forLanguage(languageCode);
    await trayManager.setToolTip(strings.studioTitle);
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(key: 'panel', label: strings.trayPanel),
          MenuItem(key: 'window', label: strings.trayWindow),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: strings.trayQuit),
        ],
      ),
    );
  }

  @override
  Future<void> showPanel() async {
    await _rememberWindowBounds();
    _mode.value = LiteriaWindowMode.panel;
    if (await windowManager.isMaximized()) await windowManager.unmaximize();
    final area = await _workArea();
    final size = Size(
      _panelWidth,
      math.min(_panelHeight, area.height - 2 * _screenMargin),
    );
    // The corner of the work area nearest to the tray icon, usually above
    // the clock.
    final tray = (await trayManager.getBounds())?.center ?? area.bottomRight;
    final left = tray.dx >= area.center.dx
        ? area.right - size.width - _screenMargin
        : area.left + _screenMargin;
    final top = tray.dy >= area.center.dy
        ? area.bottom - size.height - _screenMargin
        : area.top + _screenMargin;
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.setSkipTaskbar(true);
    await windowManager.setResizable(false);
    await windowManager.setBounds(
      Rect.fromLTWH(left, top, size.width, size.height),
    );
    await _reveal();
  }

  @override
  Future<void> showWindow() async {
    _mode.value = LiteriaWindowMode.window;
    final bounds = _windowBounds ?? await _defaultWindowBounds();
    await windowManager.setTitleBarStyle(TitleBarStyle.normal);
    await windowManager.setSkipTaskbar(false);
    await windowManager.setResizable(true);
    await windowManager.setBounds(bounds);
    if (_windowMaximized) await windowManager.maximize();
    await _reveal();
  }

  @override
  Future<void> hide() async {
    await _rememberWindowBounds();
    await windowManager.hide();
  }

  @override
  Future<void> quit() async {
    if (_quitting) return;
    _quitting = true;
    await _beforeQuit();
    await trayManager.destroy();
    await windowManager.setPreventClose(false);
    // Closes the window the ordinary way, so the engine shuts down after it.
    // windowManager.destroy() ends the message loop first and crashes the
    // app on its way out.
    await windowManager.close();
  }

  Future<void> _showCurrentMode() => switch (_mode.value) {
    LiteriaWindowMode.panel => showPanel(),
    LiteriaWindowMode.window => showWindow(),
  };

  Future<void> _reveal() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _rememberWindowBounds() async {
    if (_mode.value != LiteriaWindowMode.window) return;
    if (!await windowManager.isVisible()) return;
    // A maximized window keeps the size it had before, to restore it to.
    _windowMaximized = await windowManager.isMaximized();
    if (!_windowMaximized) _windowBounds = await windowManager.getBounds();
  }

  Future<Rect> _defaultWindowBounds() async {
    final area = await _workArea();
    return Rect.fromCenter(
      center: area.center,
      width: math.min(1280, area.width - 2 * _screenMargin),
      height: math.min(820, area.height - 2 * _screenMargin),
    );
  }

  Future<Rect> _workArea() async {
    final display = await screenRetriever.getPrimaryDisplay();
    final origin = display.visiblePosition ?? Offset.zero;
    final size = display.visibleSize ?? display.size;
    return origin & size;
  }

  @override
  void onTrayIconMouseDown() {
    // Like the calendar: a click opens the app, another click puts it away.
    unawaited(
      windowManager.isVisible().then(
        (visible) => visible ? hide() : _showCurrentMode(),
      ),
    );
  }

  @override
  void onTrayIconRightMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    unawaited(switch (menuItem.key) {
      'panel' => showPanel(),
      'window' => showWindow(),
      'quit' => quit(),
      _ => Future<void>.value(),
    });
  }

  @override
  void onWindowClose() {
    if (!_quitting) unawaited(hide());
  }
}
