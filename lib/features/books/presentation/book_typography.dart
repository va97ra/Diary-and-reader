import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

abstract final class BookTypography {
  static const bodyPoints = 12.0;
  static const titlePoints = 24.0;
  static const lineHeight = 1.5;
  static const selectionTheme = TextSelectionThemeData(
    cursorColor: AppTheme.ink,
    selectionColor: Color(0x40334155),
    selectionHandleColor: AppTheme.ink,
  );

  static double get bodySize =>
      BookPageFormat.pointsToLogicalPixels(bodyPoints);
  static double get titleSize =>
      BookPageFormat.pointsToLogicalPixels(titlePoints);

  static DefaultStyles get editorStyles => DefaultStyles(
    paragraph: _block(bodyPoints, lineHeight),
    h1: _block(24, 1.25, weight: FontWeight.bold, top: 12, bottom: 6),
    h2: _block(18, 1.3, weight: FontWeight.bold, top: 10, bottom: 5),
    h3: _block(14, 1.4, weight: FontWeight.w600, top: 8, bottom: 4),
    placeHolder: _block(bodyPoints, lineHeight, color: const Color(0xFF94A3B8)),
  );

  static DefaultTextBlockStyle _block(
    double points,
    double height, {
    FontWeight? weight,
    Color color = AppTheme.ink,
    double top = 0,
    double bottom = 0,
  }) => DefaultTextBlockStyle(
    TextStyle(
      color: color,
      fontFamily: 'Georgia',
      fontSize: BookPageFormat.pointsToLogicalPixels(points),
      height: height,
      fontWeight: weight,
      decoration: TextDecoration.none,
    ),
    HorizontalSpacing.zero,
    VerticalSpacing(top, bottom),
    VerticalSpacing.zero,
    null,
  );
}
