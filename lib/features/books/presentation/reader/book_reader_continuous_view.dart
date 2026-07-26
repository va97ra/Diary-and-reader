import 'dart:math' as math;

import 'package:dnevnik/features/books/application/book_reader_text_anchor.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_document_model.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_document_view.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_layout_engine.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_typography.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class BookReaderContinuousView extends StatelessWidget {
  const BookReaderContinuousView({
    required this.sectionId,
    required this.document,
    required this.settings,
    required this.palette,
    required this.assets,
    required this.scrollController,
    required this.highlights,
    required this.selectionGeneration,
    required this.onSelectionChanged,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onPointerMove,
    required this.onPointerSignal,
    required this.onPointerCancel,
    required this.speechTargetMode,
    this.speechRange,
    this.onSpeechTargetSelected,
    super.key,
  });

  final String sectionId;
  final BookReaderDocumentModel document;
  final BookReaderSettings settings;
  final BookReaderPalette palette;
  final Iterable<BookAsset> assets;
  final ScrollController scrollController;
  final List<BookReaderRenderHighlight> highlights;
  final int selectionGeneration;
  final ValueChanged<TextSelection?> onSelectionChanged;
  final PointerDownEventListener onPointerDown;
  final PointerUpEventListener onPointerUp;
  final PointerMoveEventListener onPointerMove;
  final void Function(PointerSignalEvent) onPointerSignal;
  final PointerCancelEventListener onPointerCancel;
  final bool speechTargetMode;
  final BookReaderTextRange? speechRange;
  final ValueChanged<int>? onSpeechTargetSelected;

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
          child: Listener(
            onPointerDown: onPointerDown,
            onPointerUp: onPointerUp,
            onPointerMove: onPointerMove,
            onPointerSignal: onPointerSignal,
            onPointerCancel: onPointerCancel,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = math
                    .max(
                      1,
                      constraints.maxWidth - settings.horizontalPadding * 2,
                    )
                    .toDouble();
                return SingleChildScrollView(
                  key: ValueKey('reader-document-$sectionId'),
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    settings.horizontalPadding,
                    settings.verticalPadding,
                    settings.horizontalPadding,
                    settings.verticalPadding,
                  ),
                  child: BookReaderDocumentView(
                    fragments: _fragments(contentWidth),
                    settings: settings,
                    palette: palette,
                    assets: assets,
                    highlights: highlights,
                    selectionGeneration: selectionGeneration,
                    onSelectionChanged: onSelectionChanged,
                    speechTargetMode: speechTargetMode,
                    speechRange: speechRange,
                    onSpeechTargetSelected: onSpeechTargetSelected,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  List<BookReaderBlockSlice> _fragments(double contentWidth) => [
    for (final block in document.blocks)
      if (block.type == BookReaderBlockType.image)
        BookReaderBlockSlice(
          block: block,
          localStart: 0,
          localEnd: 0,
          topSpacing: 0,
          bottomSpacing: 0,
          contentHeight: _imageHeight(block, contentWidth),
          totalHeight: _imageHeight(block, contentWidth),
          embedHeight: _imageHeight(block, contentWidth),
        )
      else if (!block.isText)
        BookReaderBlockSlice(
          block: block,
          localStart: 0,
          localEnd: 0,
          topSpacing: 0,
          bottomSpacing: 0,
          contentHeight: block.type == BookReaderBlockType.pageBreak ? 8 : 72,
          totalHeight: block.type == BookReaderBlockType.pageBreak ? 8 : 72,
          embedHeight: block.type == BookReaderBlockType.pageBreak ? 8 : 72,
        )
      else
        BookReaderBlockSlice(
          block: block,
          localStart: 0,
          localEnd: block.text.length,
          topSpacing: BookReaderTypography.block(
            block,
            settings,
            palette,
          ).topSpacing,
          bottomSpacing: BookReaderTypography.block(
            block,
            settings,
            palette,
          ).bottomSpacing,
          contentHeight: 0,
          totalHeight: 0,
        ),
  ];

  double _imageHeight(BookReaderBlock block, double contentWidth) {
    final width = contentWidth * block.imageWidthPercent.clamp(20, 100) / 100;
    final captionHeight = block.imageCaption.isEmpty ? 0.0 : 42.0;
    return (width * 0.72 + captionHeight + 24).clamp(120, 440).toDouble();
  }
}
