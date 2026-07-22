import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/presentation/book_typography.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_image_embed_builder.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_page_break_embed_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookMobileEditor extends StatelessWidget {
  const BookMobileEditor({
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.pageNumber,
    required this.pageCount,
    required this.pageFormat,
    required this.paragraphSettings,
    required this.assets,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.showPageNavigation,
    super.key,
  });

  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final int pageNumber;
  final int pageCount;
  final BookPageFormat pageFormat;
  final BookParagraphSettings paragraphSettings;
  final Iterable<BookAsset> assets;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final bool showPageNavigation;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const ValueKey('mobile-writing-editor'),
    color: AppTheme.paper,
    child: Padding(
      key: const ValueKey('mobile-writing-content'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Column(
        children: [
          Expanded(
            child: QuillEditor(
              controller: controller,
              focusNode: focusNode,
              scrollController: scrollController,
              config: QuillEditorConfig(
                placeholder: AppStrings.of(context).startWriting,
                padding: EdgeInsets.zero,
                customStyles: BookTypography.editorStyles(paragraphSettings),
                textSelectionThemeData: BookTypography.selectionTheme,
                embedBuilders: [
                  BookImageEmbedBuilder(assets),
                  const BookPageBreakEmbedBuilder(),
                ],
                scrollable: true,
                autoFocus: false,
              ),
            ),
          ),
          if (showPageNavigation)
            Row(
              key: const ValueKey('mobile-page-navigation'),
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onPreviousPage,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${AppStrings.of(context).a4Sheet(pageNumber, pageCount)} · '
                    '${pageFormat.widthMm.toInt()}×'
                    '${pageFormat.heightMm.toInt()} мм',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onNextPage,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}
