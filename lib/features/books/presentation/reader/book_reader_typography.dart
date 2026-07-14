import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

abstract final class BookReaderTypography {
  static DefaultStyles styles(
    BookReaderSettings settings,
    BookReaderPalette palette,
  ) => DefaultStyles(
    paragraph: _block(
      settings.fontSize,
      settings.lineHeight,
      settings.fontFamily,
      palette.ink,
      bottom: settings.fontSize * 0.45,
    ),
    h1: _block(
      settings.fontSize * 1.65,
      1.25,
      settings.fontFamily,
      palette.ink,
      weight: FontWeight.bold,
      top: 22,
      bottom: 12,
    ),
    h2: _block(
      settings.fontSize * 1.35,
      1.3,
      settings.fontFamily,
      palette.ink,
      weight: FontWeight.bold,
      top: 18,
      bottom: 10,
    ),
    h3: _block(
      settings.fontSize * 1.15,
      1.35,
      settings.fontFamily,
      palette.ink,
      weight: FontWeight.w600,
      top: 14,
      bottom: 8,
    ),
    quote: _block(
      settings.fontSize,
      settings.lineHeight,
      settings.fontFamily,
      palette.mutedInk,
      fontStyle: FontStyle.italic,
      left: 24,
      right: 16,
      top: 10,
      bottom: 10,
    ),
  );

  static DefaultTextBlockStyle _block(
    double size,
    double height,
    String fontFamily,
    Color color, {
    FontWeight? weight,
    FontStyle? fontStyle,
    double left = 0,
    double right = 0,
    double top = 0,
    double bottom = 0,
  }) => DefaultTextBlockStyle(
    TextStyle(
      color: color,
      fontFamily: fontFamily,
      fontSize: size,
      height: height,
      fontWeight: weight,
      fontStyle: fontStyle,
      decoration: TextDecoration.none,
    ),
    HorizontalSpacing(left, right),
    VerticalSpacing(top, bottom),
    VerticalSpacing.zero,
    null,
  );
}
