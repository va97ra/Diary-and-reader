import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:flutter/material.dart';

abstract final class BookReaderHighlightStyle {
  static Color displayColor(BookReaderHighlightColor color) => switch (color) {
    BookReaderHighlightColor.yellow => const Color(0xFFFFD85C),
    BookReaderHighlightColor.green => const Color(0xFF80C98B),
    BookReaderHighlightColor.blue => const Color(0xFF78B9F2),
    BookReaderHighlightColor.pink => const Color(0xFFE99AB5),
  };

  static String backgroundHex(
    BookReaderHighlightColor color,
    BookReaderPalette palette,
  ) => switch ((color, palette.brightness)) {
    (BookReaderHighlightColor.yellow, Brightness.light) => '#FFE78A',
    (BookReaderHighlightColor.green, Brightness.light) => '#BFE8C6',
    (BookReaderHighlightColor.blue, Brightness.light) => '#C4E2FA',
    (BookReaderHighlightColor.pink, Brightness.light) => '#F1C4D3',
    (BookReaderHighlightColor.yellow, Brightness.dark) => '#66561F',
    (BookReaderHighlightColor.green, Brightness.dark) => '#315A38',
    (BookReaderHighlightColor.blue, Brightness.dark) => '#294E70',
    (BookReaderHighlightColor.pink, Brightness.dark) => '#67364A',
  };
}
