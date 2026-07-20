import 'dart:math' as math;

import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_typography.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_image_embed_builder.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_page_break_embed_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookReaderPageCard extends StatelessWidget {
  const BookReaderPageCard({
    required this.width,
    required this.height,
    required this.pageNumber,
    required this.pageCount,
    required this.settings,
    required this.palette,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.editorKey,
    required this.viewportKey,
    required this.assets,
    this.isMeasurement = false,
    super.key,
  });

  final double width;
  final double height;
  final int pageNumber;
  final int pageCount;
  final BookReaderSettings settings;
  final BookReaderPalette palette;
  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final GlobalKey<EditorState> editorKey;
  final GlobalKey viewportKey;
  final List<BookAsset> assets;
  final bool isMeasurement;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = math
        .min(settings.horizontalPadding, math.max(12, (width - 140) / 2))
        .toDouble();
    final verticalPadding = math
        .min(settings.verticalPadding, math.max(12, (height - 220) / 2))
        .toDouble();
    return Container(
      key: ValueKey(
        isMeasurement ? 'reader-page-measurement' : 'reader-page-$pageNumber',
      ),
      width: width,
      height: height,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        verticalPadding,
        horizontalPadding,
        verticalPadding / 2,
      ),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isMeasurement
            ? null
            : const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRect(
              key: viewportKey,
              child: QuillEditor(
                controller: controller,
                focusNode: focusNode,
                scrollController: scrollController,
                config: QuillEditorConfig(
                  editorKey: editorKey,
                  padding: EdgeInsets.zero,
                  customStyles: BookReaderTypography.styles(settings, palette),
                  scrollable: false,
                  autoFocus: false,
                  showCursor: false,
                  embedBuilders: [
                    BookImageEmbedBuilder(assets),
                    const BookPageBreakEmbedBuilder(showLabel: false),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 16,
            child: isMeasurement
                ? null
                : Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      AppStrings.of(
                        context,
                      ).readerPageOf(pageNumber, pageCount),
                      style: TextStyle(color: palette.mutedInk, fontSize: 11),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
