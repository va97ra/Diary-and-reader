import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookFormattingToolbar extends StatelessWidget {
  const BookFormattingToolbar({
    required this.controller,
    required this.paragraphSettings,
    super.key,
  });

  final QuillController controller;
  final BookParagraphSettings paragraphSettings;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.surface,
    child: QuillSimpleToolbar(
      controller: controller,
      config: _bookToolbarConfig(paragraphSettings),
    ),
  );
}

class BookFormattingSheet extends StatelessWidget {
  const BookFormattingSheet({
    required this.controller,
    required this.paragraphSettings,
    super.key,
  });

  final QuillController controller;
  final BookParagraphSettings paragraphSettings;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: QuillSimpleToolbar(
        controller: controller,
        config: _bookToolbarConfig(paragraphSettings),
      ),
    ),
  );
}

QuillSimpleToolbarConfig _bookToolbarConfig(BookParagraphSettings settings) =>
    QuillSimpleToolbarConfig(
      multiRowsDisplay: false,
      showColorButton: false,
      showBackgroundColorButton: false,
      showSearchButton: false,
      showLineHeightButton: true,
      showAlignmentButtons: true,
      showIndent: true,
      buttonOptions: QuillSimpleToolbarButtonOptions(
        fontFamily: QuillToolbarFontFamilyButtonOptions(
          defaultDisplayText: settings.fontFamily,
          items: {for (final family in bookFontFamilies) family: family},
        ),
        fontSize: QuillToolbarFontSizeButtonOptions(
          defaultDisplayText: '${_number(settings.fontSizePt)} pt',
          items: {
            for (final points in _fontSizes)
              _number(points): _number(
                BookPageFormat.pointsToLogicalPixels(points),
              ),
          },
        ),
        selectLineHeightStyleDropdownButton:
            QuillToolbarSelectLineHeightStyleDropdownButtonOptions(
              defaultDisplayText: _number(settings.lineHeight),
            ),
      ),
    );

const _fontSizes = <double>[8, 9, 10, 11, 12, 14, 16, 18, 20, 24, 28, 32, 36];

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
