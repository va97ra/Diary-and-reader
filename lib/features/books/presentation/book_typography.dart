import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

abstract final class BookTypography {
  static const titlePoints = 24.0;
  static const selectionTheme = TextSelectionThemeData(
    cursorColor: AppTheme.ink,
    selectionColor: Color(0x40334155),
    selectionHandleColor: AppTheme.ink,
  );

  static double get titleSize =>
      BookPageFormat.pointsToLogicalPixels(titlePoints);

  static DefaultStyles editorStyles(BookParagraphSettings settings) =>
      DefaultStyles(
        paragraph: _block(
          settings.fontSizePt,
          settings.lineHeight,
          fontFamily: settings.fontFamily,
          left: BookPageFormat.millimetersToLogicalPixels(
            settings.paragraphIndentMm,
          ),
          top: BookPageFormat.pointsToLogicalPixels(settings.spacingBeforePt),
          bottom: BookPageFormat.pointsToLogicalPixels(settings.spacingAfterPt),
        ),
        h1: _block(
          24,
          1.25,
          fontFamily: settings.fontFamily,
          weight: FontWeight.bold,
          top: 12,
          bottom: 6,
        ),
        h2: _block(
          18,
          1.3,
          fontFamily: settings.fontFamily,
          weight: FontWeight.bold,
          top: 10,
          bottom: 5,
        ),
        h3: _block(
          14,
          1.4,
          fontFamily: settings.fontFamily,
          weight: FontWeight.w600,
          top: 8,
          bottom: 4,
        ),
        quote: _block(
          settings.fontSizePt,
          settings.lineHeight,
          fontFamily: settings.fontFamily,
          fontStyle: FontStyle.italic,
          left: 20,
          right: 20,
          top: 8,
          bottom: 8,
        ),
        placeHolder: _block(
          settings.fontSizePt,
          settings.lineHeight,
          fontFamily: settings.fontFamily,
          color: const Color(0xFF94A3B8),
        ),
      );

  static DefaultTextBlockStyle _block(
    double points,
    double height, {
    required String fontFamily,
    FontWeight? weight,
    FontStyle? fontStyle,
    Color color = AppTheme.ink,
    double left = 0,
    double right = 0,
    double top = 0,
    double bottom = 0,
  }) => DefaultTextBlockStyle(
    TextStyle(
      color: color,
      fontFamily: fontFamily,
      fontSize: BookPageFormat.pointsToLogicalPixels(points),
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
