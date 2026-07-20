import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_paragraph_settings_section.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_paragraph_style_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookFormattingToolbar extends StatelessWidget {
  const BookFormattingToolbar({
    required this.controller,
    required this.paragraphSettings,
    required this.onInsertImage,
    required this.onInsertPageBreak,
    super.key,
  });

  final QuillController controller;
  final BookParagraphSettings paragraphSettings;
  final VoidCallback onInsertImage;
  final VoidCallback onInsertPageBreak;

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
        IconButton(
          key: const ValueKey('insert-book-page-break-button'),
          tooltip: AppStrings.of(context).insertPageBreak,
          onPressed: onInsertPageBreak,
          icon: const Icon(Icons.insert_page_break_outlined),
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
    required this.workspaceController,
    required this.controller,
    required this.paragraphSettings,
    required this.onInsertImage,
    required this.onInsertPageBreak,
    super.key,
  });

  final AuthorWorkspaceController workspaceController;
  final QuillController controller;
  final BookParagraphSettings paragraphSettings;
  final VoidCallback onInsertImage;
  final VoidCallback onInsertPageBreak;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.of(context).writerFormatting,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('insert-book-page-break-button'),
              onPressed: onInsertPageBreak,
              icon: const Icon(Icons.insert_page_break_outlined),
              label: Text(AppStrings.of(context).insertPageBreak),
            ),
          ),
          const SizedBox(height: 10),
          QuillSimpleToolbar(
            controller: controller,
            config: _bookToolbarConfig(paragraphSettings),
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),
          BookParagraphSettingsSection(controller: workspaceController),
        ],
      ),
    ),
  );
}

QuillSimpleToolbarConfig _bookToolbarConfig(BookParagraphSettings settings) =>
    QuillSimpleToolbarConfig(
      multiRowsDisplay: true,
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
