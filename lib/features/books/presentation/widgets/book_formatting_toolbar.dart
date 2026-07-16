import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_paragraph_style_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookFormattingToolbar extends StatelessWidget {
  const BookFormattingToolbar({
    required this.controller,
    required this.paragraphSettings,
    required this.onInsertImage,
    super.key,
  });

  final QuillController controller;
  final BookParagraphSettings paragraphSettings;
  final VoidCallback onInsertImage;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.surface,
    child: Row(
      children: [
        SizedBox(
          width: 210,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
            child: BookParagraphStyleSelector(controller: controller),
          ),
        ),
        const SizedBox(height: 34, child: VerticalDivider(width: 12)),
        IconButton(
          key: const ValueKey('insert-book-image-button'),
          tooltip: AppStrings.of(context).insertImage,
          onPressed: onInsertImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
        ),
        const SizedBox(height: 34, child: VerticalDivider(width: 12)),
        Expanded(
          child: QuillSimpleToolbar(
            controller: controller,
            config: _bookToolbarConfig(paragraphSettings),
          ),
        ),
      ],
    ),
  );
}

class BookFormattingSheet extends StatelessWidget {
  const BookFormattingSheet({
    required this.controller,
    required this.paragraphSettings,
    required this.onInsertImage,
    super.key,
  });

  final QuillController controller;
  final BookParagraphSettings paragraphSettings;
  final VoidCallback onInsertImage;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BookParagraphStyleSelector(controller: controller),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('insert-book-image-button'),
              onPressed: onInsertImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(AppStrings.of(context).insertImage),
            ),
          ),
          const SizedBox(height: 10),
          QuillSimpleToolbar(
            controller: controller,
            config: _bookToolbarConfig(paragraphSettings),
          ),
        ],
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
