import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/presentation/book_typography.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_image_embed_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookPageCanvas extends StatelessWidget {
  const BookPageCanvas({
    required this.pageNumber,
    required this.scale,
    required this.pageFormat,
    required this.paragraphSettings,
    required this.assets,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.editorKey,
    required this.viewportKey,
    required this.titleController,
    required this.onTitleChanged,
    this.isMeasurement = false,
    super.key,
  });

  final int pageNumber;
  final double scale;
  final BookPageFormat pageFormat;
  final BookParagraphSettings paragraphSettings;
  final Iterable<BookAsset> assets;
  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final GlobalKey<EditorState> editorKey;
  final GlobalKey viewportKey;
  final TextEditingController titleController;
  final ValueChanged<String> onTitleChanged;
  final bool isMeasurement;

  bool get _isFirstPage => pageNumber == 1;

  @override
  Widget build(BuildContext context) {
    final page = MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(
        width: pageFormat.width,
        height: pageFormat.height,
        decoration: BoxDecoration(
          color: AppTheme.paper,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                pageFormat.marginLeft,
                pageFormat.marginTop,
                pageFormat.marginRight,
                pageFormat.marginBottom,
              ),
              child: Column(
                children: [
                  if (_isFirstPage) ...[
                    TextField(
                      controller: titleController,
                      cursorColor: AppTheme.ink,
                      onChanged: onTitleChanged,
                      maxLines: 2,
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontFamily: paragraphSettings.fontFamily,
                        fontSize: BookTypography.titleSize,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.of(context).newChapter,
                        hintStyle: const TextStyle(color: Colors.blueGrey),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFE2E8F0), height: 1),
                    const SizedBox(height: 16),
                  ],
                  Expanded(
                    child: ClipRect(
                      key: viewportKey,
                      child: QuillEditor(
                        controller: controller,
                        focusNode: focusNode,
                        scrollController: scrollController,
                        config: QuillEditorConfig(
                          editorKey: editorKey,
                          placeholder: AppStrings.of(context).startWriting,
                          padding: EdgeInsets.zero,
                          customStyles: BookTypography.editorStyles(
                            paragraphSettings,
                          ),
                          textSelectionThemeData: BookTypography.selectionTheme,
                          embedBuilders: [BookImageEmbedBuilder(assets)],
                          scrollable: false,
                          autoFocus: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: pageFormat.marginLeft,
              right: pageFormat.marginRight,
              bottom: (pageFormat.marginBottom / 2 - 7).clamp(4, 32),
              child: Text(
                '${AppStrings.of(context).page} $pageNumber · '
                'A4 ${pageFormat.widthMm.toInt()}×'
                '${pageFormat.heightMm.toInt()} мм',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      key: ValueKey(
        isMeasurement ? 'book-page-measurement' : 'book-page-$pageNumber',
      ),
      width: pageFormat.width * scale,
      height: pageFormat.height * scale,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: pageFormat.width,
        maxWidth: pageFormat.width,
        minHeight: pageFormat.height,
        maxHeight: pageFormat.height,
        child: Transform.scale(
          alignment: Alignment.topLeft,
          scale: scale,
          child: page,
        ),
      ),
    );
  }
}
