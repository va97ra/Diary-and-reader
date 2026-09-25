import 'package:dnevnik/app/desktop/literia_desktop_shell.dart';

/// Without a desktop tray there is no shell: the app keeps its own window.
Future<LiteriaDesktopShell?> startLiteriaDesktopShell({
  required List<String> arguments,
  required String languageCode,
  required Future<void> Function() beforeQuit,
}) async => null;
