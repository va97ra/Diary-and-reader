import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const background = Color(0xFF24160F);
  static const surface = Color(0xFF3B261B);
  static const accent = Color(0xFFFBBF24);
  static const paper = Color(0xFFF7EEDC);
  static const ink = Color(0xFF35271F);
  static const stitch = Color(0xFFB58A5A);

  static ThemeData get light => _theme(Brightness.light);

  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
          surface: dark ? surface : paper,
        ).copyWith(
          primary: dark ? accent : const Color(0xFF8A5A14),
          onPrimary: dark ? background : Colors.white,
          surface: dark ? surface : paper,
          onSurface: dark ? const Color(0xFFFFF4E6) : ink,
          outline: dark
              ? stitch.withValues(alpha: 0.72)
              : const Color(0xFF9D8062),
        );
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.72)),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF1B100B)
          : const Color(0xFFF3E7D3),
      fontFamily: 'Segoe UI',
      visualDensity: VisualDensity.compact,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: const Color(0xFFFFF4E6),
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: Color(0xFFFFF4E6),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: dark ? const Color(0xFF342218) : const Color(0xFFFFF8EC),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.48)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: dark ? const Color(0x75180C07) : const Color(0xA6FFF9EF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(40, 40),
          maximumSize: const Size(44, 44),
          padding: const EdgeInsets.all(8),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          minimumSize: const Size(40, 38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(48, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          minimumSize: const Size(48, 40),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.75)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        constraints: const BoxConstraints(minHeight: 44),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: scheme.outline.withValues(alpha: 0.62)),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? surface : paper,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline.withValues(alpha: 0.34),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
