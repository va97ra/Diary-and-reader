import 'dart:collection';
import 'dart:math' as math;

import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_document_model.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_typography.dart';
import 'package:flutter/material.dart';

class BookReaderPageMetrics {
  const BookReaderPageMetrics({
    required this.width,
    required this.height,
    required this.horizontalPadding,
    required this.topPadding,
    required this.bottomPadding,
    required this.footerHeight,
  });

  factory BookReaderPageMetrics.resolve({
    required double width,
    required double height,
    required BookReaderSettings settings,
  }) {
    final horizontalPadding = math
        .min(
          math.min(settings.horizontalPadding, math.max(12, (width - 140) / 2)),
          math.max(0, (width - 1) / 2),
        )
        .toDouble();
    final footerHeight = math.min(16, height).toDouble();
    final verticalPadding = math
        .min(
          math.min(settings.verticalPadding, math.max(12, (height - 220) / 2)),
          math.max(0, (height - footerHeight) / 1.5),
        )
        .toDouble();
    return BookReaderPageMetrics(
      width: width,
      height: height,
      horizontalPadding: horizontalPadding,
      topPadding: verticalPadding,
      bottomPadding: verticalPadding / 2,
      footerHeight: footerHeight,
    );
  }

  final double width;
  final double height;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double footerHeight;

  double get contentWidth =>
      math.max(1, width - horizontalPadding * 2).toDouble();

  double get contentHeight => math
      .max(1, height - topPadding - bottomPadding - footerHeight)
      .toDouble();
}

class BookReaderBlockSlice {
  const BookReaderBlockSlice({
    required this.block,
    required this.localStart,
    required this.localEnd,
    required this.topSpacing,
    required this.bottomSpacing,
    required this.contentHeight,
    required this.totalHeight,
    this.embedHeight,
  });

  final BookReaderBlock block;
  final int localStart;
  final int localEnd;
  final double topSpacing;
  final double bottomSpacing;
  final double contentHeight;
  final double totalHeight;
  final double? embedHeight;

  bool get startsBlock => localStart == 0;
  bool get endsBlock => localEnd >= block.text.length;

  int get sourceStart =>
      block.isText ? block.sourceStart + localStart : block.sourceStart;

  int get sourceEnd =>
      block.isText ? block.sourceStart + localEnd : block.sourceEnd;
}

class BookReaderPageLayout {
  const BookReaderPageLayout({
    required this.fragments,
    required this.sourceStart,
    required this.sourceEnd,
  });

  final List<BookReaderBlockSlice> fragments;
  final int sourceStart;
  final int sourceEnd;
}

class BookReaderLayoutEngine {
  final LinkedHashMap<_BookReaderLayoutCacheKey, List<BookReaderPageLayout>>
  _cache = LinkedHashMap();

  List<BookReaderPageLayout> paginate({
    required BookReaderDocumentModel document,
    required BookReaderSettings settings,
    required BookReaderPalette palette,
    required BookReaderPageMetrics metrics,
    required Locale locale,
  }) {
    final key = _BookReaderLayoutCacheKey(
      document: document,
      settings: settings,
      width: metrics.width,
      height: metrics.height,
      locale: locale,
    );
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }
    final pages = _paginate(
      document: document,
      settings: settings,
      palette: palette,
      metrics: metrics,
      locale: locale,
    );
    _cache[key] = pages;
    while (_cache.length > 8) {
      _cache.remove(_cache.keys.first);
    }
    return pages;
  }

  void clear() => _cache.clear();

  List<BookReaderPageLayout> _paginate({
    required BookReaderDocumentModel document,
    required BookReaderSettings settings,
    required BookReaderPalette palette,
    required BookReaderPageMetrics metrics,
    required Locale locale,
  }) {
    final pages = <BookReaderPageLayout>[];
    var fragments = <BookReaderBlockSlice>[];
    var remainingHeight = metrics.contentHeight;

    void finishPage() {
      if (fragments.isEmpty) return;
      pages.add(
        BookReaderPageLayout(
          fragments: List.unmodifiable(fragments),
          sourceStart: fragments.first.sourceStart,
          sourceEnd: fragments.last.sourceEnd,
        ),
      );
      fragments = <BookReaderBlockSlice>[];
      remainingHeight = metrics.contentHeight;
    }

    for (final block in document.blocks) {
      if (block.type == BookReaderBlockType.pageBreak) {
        finishPage();
        continue;
      }
      if (!block.isText) {
        final height = _embedHeight(block, metrics);
        if (fragments.isNotEmpty && height > remainingHeight) finishPage();
        final fittedHeight = math.min(height, remainingHeight).toDouble();
        fragments.add(
          BookReaderBlockSlice(
            block: block,
            localStart: 0,
            localEnd: 0,
            topSpacing: 0,
            bottomSpacing: 0,
            contentHeight: fittedHeight,
            totalHeight: fittedHeight,
            embedHeight: fittedHeight,
          ),
        );
        remainingHeight -= fittedHeight;
        if (remainingHeight < 1) finishPage();
        continue;
      }

      final typography = BookReaderTypography.block(block, settings, palette);
      final textLength = block.text.length;
      final prefix = typography.prefix;
      final prefixLength = prefix.length;
      final availableWidth = math
          .max(
            24,
            metrics.contentWidth - typography.leftInset - typography.rightInset,
          )
          .toDouble();
      final blockPainter = _textPainter(
        block: block,
        typography: typography,
        localStart: 0,
        localEnd: textLength,
        prefix: prefix,
        width: availableWidth,
        locale: locale,
      );
      final lineMetrics = blockPainter.computeLineMetrics();
      final lineEnds = <int>[];
      final remainingLineHeights = List<double>.filled(
        lineMetrics.length + 1,
        0,
      );
      var previousLineEnd = 0;
      for (var index = 0; index < lineMetrics.length; index++) {
        final line = lineMetrics[index];
        final position = blockPainter.getPositionForOffset(
          Offset(availableWidth - 0.5, math.max(0, line.baseline - 0.5)),
        );
        final boundary = blockPainter.getLineBoundary(position);
        var lineEnd = (boundary.end - prefixLength).clamp(0, textLength);
        if (lineEnd <= previousLineEnd && previousLineEnd < textLength) {
          lineEnd = math.min(textLength, previousLineEnd + 1);
        }
        lineEnds.add(lineEnd);
        previousLineEnd = lineEnd;
      }
      for (var index = lineMetrics.length - 1; index >= 0; index--) {
        remainingLineHeights[index] =
            lineMetrics[index].height + remainingLineHeights[index + 1];
      }
      var localStart = 0;
      var lineIndex = 0;
      var firstFragment = true;
      do {
        final topSpacing = firstFragment ? typography.topSpacing : 0.0;
        final emptyHeight =
            (typography.textStyle.fontSize ?? 16) *
            (typography.textStyle.height ?? 1.2);
        final remainingLineHeight = remainingLineHeights[lineIndex];
        final fullTextHeight = textLength == 0
            ? emptyHeight
            : remainingLineHeight;
        final fullHeight =
            topSpacing + fullTextHeight + typography.bottomSpacing;
        if (fullHeight <= remainingHeight + 0.5) {
          fragments.add(
            BookReaderBlockSlice(
              block: block,
              localStart: localStart,
              localEnd: textLength,
              topSpacing: topSpacing,
              bottomSpacing: typography.bottomSpacing,
              contentHeight: fullTextHeight,
              totalHeight: fullHeight,
            ),
          );
          remainingHeight -= fullHeight;
          break;
        }

        final availableTextHeight = remainingHeight - topSpacing;
        var fittingLineCount = 0;
        var contentHeight = 0.0;
        for (var index = lineIndex; index < lineMetrics.length; index++) {
          final nextHeight = contentHeight + lineMetrics[index].height;
          if (nextHeight > availableTextHeight + 0.5) break;
          contentHeight = nextHeight;
          fittingLineCount++;
        }
        if (fittingLineCount == 0 && fragments.isNotEmpty) {
          finishPage();
          continue;
        }
        if (textLength == 0) {
          final height = math
              .min(remainingHeight, topSpacing + emptyHeight)
              .toDouble();
          fragments.add(
            BookReaderBlockSlice(
              block: block,
              localStart: 0,
              localEnd: 0,
              topSpacing: topSpacing,
              bottomSpacing: 0,
              contentHeight: math.max(0, height - topSpacing).toDouble(),
              totalHeight: height,
            ),
          );
          remainingHeight -= height;
          break;
        }

        if (fittingLineCount == 0) {
          fittingLineCount = 1;
          contentHeight = lineMetrics[lineIndex].height;
        }
        final lastLineIndex = math.min(
          lineMetrics.length - 1,
          lineIndex + fittingLineCount - 1,
        );
        var localEnd = lineEnds[lastLineIndex];
        if (localEnd <= localStart) {
          localEnd = math.min(textLength, localStart + 1);
        }
        final isLast = localEnd >= textLength;
        final bottomSpacing = isLast ? typography.bottomSpacing : 0.0;
        final totalHeight = math
            .min(remainingHeight, topSpacing + contentHeight + bottomSpacing)
            .toDouble();
        fragments.add(
          BookReaderBlockSlice(
            block: block,
            localStart: localStart,
            localEnd: localEnd,
            topSpacing: topSpacing,
            bottomSpacing: bottomSpacing,
            contentHeight: contentHeight,
            totalHeight: totalHeight,
          ),
        );
        remainingHeight -= totalHeight;
        localStart = localEnd;
        lineIndex = lastLineIndex + 1;
        firstFragment = false;
        if (localStart < textLength) finishPage();
      } while (localStart < textLength || textLength == 0 && firstFragment);
    }
    finishPage();
    return pages.isEmpty
        ? const [
            BookReaderPageLayout(fragments: [], sourceStart: 0, sourceEnd: 0),
          ]
        : List.unmodifiable(pages);
  }

  TextPainter _textPainter({
    required BookReaderBlock block,
    required BookReaderBlockTypography typography,
    required int localStart,
    required int localEnd,
    required String prefix,
    required double width,
    required Locale locale,
  }) {
    final span = textSpanForRange(
      block,
      typography,
      localStart: localStart,
      localEnd: localEnd,
      prefix: prefix,
    );
    return TextPainter(
      text: span,
      textAlign: typography.textAlign,
      textDirection: typography.textDirection,
      textScaler: TextScaler.noScaling,
      locale: locale,
    )..layout(maxWidth: width);
  }

  double _embedHeight(BookReaderBlock block, BookReaderPageMetrics metrics) {
    if (block.type == BookReaderBlockType.unsupportedEmbed) return 72;
    final width =
        metrics.contentWidth * block.imageWidthPercent.clamp(20, 100) / 100;
    final captionHeight = block.imageCaption.isEmpty ? 0.0 : 42.0;
    return math
        .min(metrics.contentHeight * 0.72, width * 0.72 + captionHeight + 24)
        .clamp(96, metrics.contentHeight)
        .toDouble();
  }
}

TextSpan textSpanForRange(
  BookReaderBlock block,
  BookReaderBlockTypography typography, {
  required int localStart,
  required int localEnd,
  String prefix = '',
}) {
  final children = <InlineSpan>[if (prefix.isNotEmpty) TextSpan(text: prefix)];
  var runStart = 0;
  for (final run in block.runs) {
    final runEnd = runStart + run.text.length;
    final overlapStart = math.max(localStart, runStart);
    final overlapEnd = math.min(localEnd, runEnd);
    if (overlapStart < overlapEnd) {
      children.add(
        TextSpan(
          text: run.text.substring(
            overlapStart - runStart,
            overlapEnd - runStart,
          ),
          style: BookReaderTypography.run(run, typography.textStyle),
        ),
      );
    }
    runStart = runEnd;
    if (runStart >= localEnd) break;
  }
  if (children.isEmpty ||
      children.every((child) => child is TextSpan && child.text!.isEmpty)) {
    children.add(const TextSpan(text: '\u200B'));
  }
  return TextSpan(style: typography.textStyle, children: children);
}

class _BookReaderLayoutCacheKey {
  const _BookReaderLayoutCacheKey({
    required this.document,
    required this.settings,
    required this.width,
    required this.height,
    required this.locale,
  });

  final BookReaderDocumentModel document;
  final BookReaderSettings settings;
  final double width;
  final double height;
  final Locale locale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BookReaderLayoutCacheKey &&
          identical(document, other.document) &&
          settings == other.settings &&
          (width - other.width).abs() < 0.5 &&
          (height - other.height).abs() < 0.5 &&
          locale == other.locale;

  @override
  int get hashCode => Object.hash(
    identityHashCode(document),
    settings,
    width.round(),
    height.round(),
    locale,
  );
}
