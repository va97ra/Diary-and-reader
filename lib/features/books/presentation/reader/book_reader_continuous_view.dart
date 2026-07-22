import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_typography.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_image_embed_builder.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_page_break_embed_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookReaderContinuousView extends StatelessWidget {
  const BookReaderContinuousView({
    required this.sectionId,
    required this.settings,
    required this.palette,
    required this.assets,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onPointerCancel,
    super.key,
  });

  final String sectionId;
  final BookReaderSettings settings;
  final BookReaderPalette palette;
  final Iterable<BookAsset> assets;
  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final PointerDownEventListener onPointerDown;
  final PointerUpEventListener onPointerUp;
  final PointerCancelEventListener onPointerCancel;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const ValueKey('reader-continuous-view'),
    color: palette.background,
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: settings.contentWidth + settings.horizontalPadding * 2,
        ),
        child: Container(
          key: const ValueKey('reader-surface'),
          width: double.infinity,
          color: palette.surface,
          padding: EdgeInsets.fromLTRB(
            settings.horizontalPadding,
            settings.verticalPadding,
            settings.horizontalPadding,
            8,
          ),
          child: Listener(
            onPointerDown: onPointerDown,
            onPointerUp: onPointerUp,
            onPointerCancel: onPointerCancel,
            child: QuillEditor(
              key: ValueKey('reader-document-$sectionId'),
              controller: controller,
              focusNode: focusNode,
              scrollController: scrollController,
              config: QuillEditorConfig(
                padding: EdgeInsets.zero,
                customStyles: BookReaderTypography.styles(settings, palette),
                scrollable: true,
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
      ),
    ),
  );
}
