import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFF0D0F1A);
  static const surface = Color(0xFF1E293B);
  static const accent = Color(0xFFFBBF24);
  static const paper = Color(0xFFFDFBF7);
  static const ink = Color(0xFF334155);

  static ThemeData get light => _theme(Brightness.light);

  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
      surface: brightness == Brightness.dark
          ? surface
          : const Color(0xFFFFFBF3),
    ),
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? background
        : const Color(0xFFF5EBDD),
    fontFamily: 'Segoe UI',
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      filled: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: brightness == Brightness.dark
          ? surface
          : const Color(0xFFFFFBF3),
    ),
  );
}
