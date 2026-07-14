import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFF0D0F1A);
  static const surface = Color(0xFF1E293B);
  static const accent = Color(0xFFFBBF24);
  static const paper = Color(0xFFFDFBF7);
  static const ink = Color(0xFF334155);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: surface,
    ),
    scaffoldBackgroundColor: background,
    fontFamily: 'Segoe UI',
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      filled: false,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: surface),
  );
}
