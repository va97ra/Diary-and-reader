import 'dart:math' as math;

import 'package:dnevnik/features/books/application/book_reader_text_anchor.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_image_placement.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_document_model.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_highlight_style.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_layout_engine.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BookReaderRenderHighlight {
  const BookReaderRenderHighlight({
    required this.start,
    required this.end,
    required this.color,
  });

  final int start;
  final int end;
  final BookReaderHighlightColor color;
}

class BookReaderDocumentView extends StatelessWidget {
  const BookReaderDocumentView({
    required this.fragments,
    required this.settings,
    required this.palette,
    required this.assets,
    required this.highlights,
    required this.selectionGeneration,
    required this.onSelectionChanged,
    required this.speechTargetMode,
    this.speechRange,
    this.onSpeechTargetSelected,
    this.constrainToMeasuredHeight = false,
    super.key,
  });

  final List<BookReaderBlockSlice> fragments;
  final BookReaderSettings settings;
  final BookReaderPalette palette;
  final Iterable<BookAsset> assets;
  final List<BookReaderRenderHighlight> highlights;
  final int selectionGeneration;
  final ValueChanged<TextSelection?> onSelectionChanged;
  final bool speechTargetMode;
  final BookReaderTextRange? speechRange;
  final ValueChanged<int>? onSpeechTargetSelected;
  final bool constrainToMeasuredHeight;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final fragment in fragments)
        _BookReaderBlockFragmentView(
          key: ValueKey(
            'reader-fragment-${fragment.block.sourceStart}-'
            '${fragment.localStart}-$selectionGeneration',
          ),
          fragment: fragment,
          settings: settings,
          palette: palette,
          assets: assets,
          highlights: highlights,
          selectionGeneration: selectionGeneration,
          onSelectionChanged: onSelectionChanged,
          speechTargetMode: speechTargetMode,
          speechRange: speechRange,
          onSpeechTargetSelected: onSpeechTargetSelected,
          constrainToMeasuredHeight: constrainToMeasuredHeight,
        ),
    ],
  );
}

class _BookReaderBlockFragmentView extends StatelessWidget {
  const _BookReaderBlockFragmentView({
    required this.fragment,
    required this.settings,
    required this.palette,
    required this.assets,
    required this.highlights,
    required this.selectionGeneration,
    required this.onSelectionChanged,
    required this.speechTargetMode,
    required this.speechRange,
    required this.onSpeechTargetSelected,
    required this.constrainToMeasuredHeight,
    super.key,
  });

  final BookReaderBlockSlice fragment;
  final BookReaderSettings settings;
  final BookReaderPalette palette;
  final Iterable<BookAsset> assets;
  final List<BookReaderRenderHighlight> highlights;
  final int selectionGeneration;
  final ValueChanged<TextSelection?> onSelectionChanged;
  final bool speechTargetMode;
  final BookReaderTextRange? speechRange;
  final ValueChanged<int>? onSpeechTargetSelected;
  final bool constrainToMeasuredHeight;

  @override
  Widget build(BuildContext context) {
    final block = fragment.block;
    if (block.type == BookReaderBlockType.pageBreak) {
      return const SizedBox(height: 8);
    }
    if (block.type == BookReaderBlockType.image) {
      return _BookReaderImageFragment(
        block: block,
        assets: assets,
        palette: palette,
        height: fragment.embedHeight,
      );
    }
    if (block.type == BookReaderBlockType.unsupportedEmbed) {
      return SizedBox(
        height: fragment.embedHeight ?? 72,
        child: Center(
          child: Icon(Icons.extension_off_outlined, color: palette.mutedInk),
        ),
      );
    }
    final typography = BookReaderTypography.block(block, settings, palette);
    final prefix = fragment.startsBlock ? typography.prefix : '';
    final span = _styledSpan(
      block,
      typography,
      localStart: fragment.localStart,
      localEnd: fragment.localEnd,
      prefix: prefix,
      palette: palette,
      highlights: highlights,
      speechRange: speechRange,
    );
    final text = BookReaderTextFragment(
      key: ValueKey(
        'reader-text-${block.sourceStart}-${fragment.localStart}-'
        '$selectionGeneration',
      ),
      span: span,
      typography: typography,
      prefixLength: prefix.length,
      sourceStart: block.sourceStart + fragment.localStart,
      sourceEnd: block.sourceStart + fragment.localEnd,
      onSelectionChanged: onSelectionChanged,
      speechTargetMode: speechTargetMode,
      onSpeechTargetSelected: onSpeechTargetSelected,
    );
    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        typography.leftInset,
        fragment.topSpacing,
        typography.rightInset,
        fragment.bottomSpacing,
      ),
      child: text,
    );
    if (!constrainToMeasuredHeight) return content;
    return SizedBox(
      height: fragment.totalHeight,
      child: ClipRect(child: content),
    );
  }
}

class BookReaderTextFragment extends StatelessWidget {
  const BookReaderTextFragment({
    required this.span,
    required this.typography,
    required this.prefixLength,
    required this.sourceStart,
    required this.sourceEnd,
    required this.onSelectionChanged,
    required this.speechTargetMode,
    required this.onSpeechTargetSelected,
    super.key,
  });

  final TextSpan span;
  final BookReaderBlockTypography typography;
  final int prefixLength;
  final int sourceStart;
  final int sourceEnd;
  final ValueChanged<TextSelection?> onSelectionChanged;
  final bool speechTargetMode;
  final ValueChanged<int>? onSpeechTargetSelected;

  void selectSpeechOffset(int localOffset) {
    onSpeechTargetSelected?.call(
      sourceStart + localOffset.clamp(0, sourceEnd - sourceStart),
    );
  }

  void selectRange(TextSelection selection) {
    if (selection.isCollapsed) {
      onSelectionChanged(null);
      return;
    }
    final base = (selection.baseOffset - prefixLength).clamp(
      0,
      sourceEnd - sourceStart,
    );
    final extent = (selection.extentOffset - prefixLength).clamp(
      0,
      sourceEnd - sourceStart,
    );
    onSelectionChanged(
      TextSelection(
        baseOffset: sourceStart + base,
        extentOffset: sourceStart + extent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (speechTargetMode && onSpeechTargetSelected != null) {
      final textKey = GlobalKey();
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final renderObject = textKey.currentContext?.findRenderObject();
          if (renderObject is! RenderParagraph) return;
          final position = renderObject.getPositionForOffset(
            details.localPosition,
          );
          final localOffset = (position.offset - prefixLength)
              .clamp(0, sourceEnd - sourceStart)
              .toInt();
          selectSpeechOffset(localOffset);
        },
        child: RichText(
          key: textKey,
          text: span,
          textAlign: typography.textAlign,
          textDirection: typography.textDirection,
          textScaler: TextScaler.noScaling,
        ),
      );
    }
    return SelectableText.rich(
      span,
      textAlign: typography.textAlign,
      textDirection: typography.textDirection,
      textScaler: TextScaler.noScaling,
      enableInteractiveSelection: true,
      onSelectionChanged: (selection, _) => selectRange(selection),
    );
  }
}

class _BookReaderImageFragment extends StatelessWidget {
  const _BookReaderImageFragment({
    required this.block,
    required this.assets,
    required this.palette,
    required this.height,
  });

  final BookReaderBlock block;
  final Iterable<BookAsset> assets;
  final BookReaderPalette palette;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final asset = assets.where((item) => item.id == block.assetId).firstOrNull;
    final alignment = switch (block.imageAlignment) {
      BookImageAlignment.left => Alignment.centerLeft,
      BookImageAlignment.center => Alignment.center,
      BookImageAlignment.right => Alignment.centerRight,
    };
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Align(
          alignment: alignment,
          child: FractionallySizedBox(
            widthFactor: block.imageWidthPercent.clamp(20, 100) / 100,
            child: Column(
              children: [
                Expanded(
                  child: asset == null || !asset.isRenderableImage
                      ? Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: palette.mutedInk,
                          ),
                        )
                      : Image.memory(
                          asset.bytes,
                          key: ValueKey('book-image-${asset.id}'),
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          cacheWidth: 1200,
                          errorBuilder: (_, _, _) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: palette.mutedInk,
                            ),
                          ),
                        ),
                ),
                if (block.imageCaption.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    block.imageCaption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: palette.mutedInk,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

TextSpan _styledSpan(
  BookReaderBlock block,
  BookReaderBlockTypography typography, {
  required int localStart,
  required int localEnd,
  required String prefix,
  required BookReaderPalette palette,
  required List<BookReaderRenderHighlight> highlights,
  required BookReaderTextRange? speechRange,
}) {
  final children = <InlineSpan>[if (prefix.isNotEmpty) TextSpan(text: prefix)];
  var runLocalStart = 0;
  for (final run in block.runs) {
    final runLocalEnd = runLocalStart + run.text.length;
    final overlapStart = math.max(localStart, runLocalStart);
    final overlapEnd = math.min(localEnd, runLocalEnd);
    if (overlapStart < overlapEnd) {
      final globalStart = block.sourceStart + overlapStart;
      final globalEnd = block.sourceStart + overlapEnd;
      final boundaries = <int>{globalStart, globalEnd};
      for (final highlight in highlights) {
        if (highlight.end <= globalStart || highlight.start >= globalEnd) {
          continue;
        }
        boundaries
          ..add(highlight.start.clamp(globalStart, globalEnd))
          ..add(highlight.end.clamp(globalStart, globalEnd));
      }
      if (speechRange != null &&
          speechRange.end > globalStart &&
          speechRange.start < globalEnd) {
        boundaries
          ..add(speechRange.start.clamp(globalStart, globalEnd))
          ..add(speechRange.end.clamp(globalStart, globalEnd));
      }
      final ordered = boundaries.toList()..sort();
      for (var index = 0; index < ordered.length - 1; index++) {
        final segmentStart = ordered[index];
        final segmentEnd = ordered[index + 1];
        if (segmentEnd <= segmentStart) continue;
        final speechHighlighted =
            speechRange != null &&
            segmentStart < speechRange.end &&
            segmentEnd > speechRange.start;
        final annotation = highlights
            .where(
              (highlight) =>
                  segmentStart < highlight.end && segmentEnd > highlight.start,
            )
            .firstOrNull;
        final background = speechHighlighted
            ? BookReaderTypography.color(
                BookReaderHighlightStyle.backgroundHex(
                  BookReaderHighlightColor.blue,
                  palette,
                ),
              )
            : annotation == null
            ? null
            : BookReaderTypography.color(
                BookReaderHighlightStyle.backgroundHex(
                  annotation.color,
                  palette,
                ),
              );
        children.add(
          TextSpan(
            text: run.text.substring(
              segmentStart - block.sourceStart - runLocalStart,
              segmentEnd - block.sourceStart - runLocalStart,
            ),
            style: BookReaderTypography.run(
              run,
              typography.textStyle,
              backgroundColor: background,
            ),
          ),
        );
      }
    }
    runLocalStart = runLocalEnd;
    if (runLocalStart >= localEnd) break;
  }
  if (children.isEmpty ||
      children.every((child) => child is TextSpan && child.text!.isEmpty)) {
    children.add(const TextSpan(text: '\u200B'));
  }
  return TextSpan(style: typography.textStyle, children: children);
}
