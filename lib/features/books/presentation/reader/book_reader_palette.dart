import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:flutter/material.dart';

class BookReaderPalette {
  const BookReaderPalette({
    required this.background,
    required this.surface,
    required this.ink,
    required this.mutedInk,
    required this.divider,
    required this.brightness,
  });

  factory BookReaderPalette.forTheme(BookReaderTheme theme) => switch (theme) {
    BookReaderTheme.light => const BookReaderPalette(
      background: Color(0xFFF4F5F7),
      surface: Color(0xFFFFFFFF),
      ink: Color(0xFF20242B),
      mutedInk: Color(0xFF68717D),
      divider: Color(0xFFDDE1E6),
      brightness: Brightness.light,
    ),
    BookReaderTheme.sepia => const BookReaderPalette(
      background: Color(0xFFE9DFC9),
      surface: Color(0xFFF7EEDB),
      ink: Color(0xFF40372D),
      mutedInk: Color(0xFF786B5A),
      divider: Color(0xFFD9CBAF),
      brightness: Brightness.light,
    ),
    BookReaderTheme.dark => const BookReaderPalette(
      background: Color(0xFF111318),
      surface: Color(0xFF1B1E25),
      ink: Color(0xFFE7E2D8),
      mutedInk: Color(0xFFA4A8B0),
      divider: Color(0xFF353942),
      brightness: Brightness.dark,
    ),
  };

  final Color background;
  final Color surface;
  final Color ink;
  final Color mutedInk;
  final Color divider;
  final Brightness brightness;

  ThemeData themeData(ThemeData base) => base.copyWith(
    brightness: brightness,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF9A6A2F),
      brightness: brightness,
      surface: surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
      surfaceTintColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
    ),
    dividerColor: divider,
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    sliderTheme: base.sliderTheme.copyWith(
      showValueIndicator: ShowValueIndicator.onDrag,
    ),
  );
}
