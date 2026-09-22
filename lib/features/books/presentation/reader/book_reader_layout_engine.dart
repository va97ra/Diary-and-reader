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

/// Caches paginations per document, settings, and page geometry. A
/// pagination is computed incrementally, so long chapters never block a frame.
class BookReaderLayoutEngine {
  final LinkedHashMap<_BookReaderLayoutCacheKey, BookReaderPagination> _cache =
      LinkedHashMap();

  BookReaderPagination paginate({
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
    final pagination = BookReaderPagination._(
      document: document,
      settings: settings,
      palette: palette,
      metrics: metrics,
      locale: locale,
    );
    _cache[key] = pagination;
    while (_cache.length > 8) {
      _cache.remove(_cache.keys.first);
    }
    return pagination;
  }

  void clear() => _cache.clear();
}

/// Pages of one chapter, laid out block by block on demand.
class BookReaderPagination {
  BookReaderPagination._({
    required this.document,
    required this.settings,
    required this.palette,
    required this.metrics,
    required this.locale,
  }) : _remainingHeight = metrics.contentHeight;

  final BookReaderDocumentModel document;
  final BookReaderSettings settings;
  final BookReaderPalette palette;
  final BookReaderPageMetrics metrics;
  final Locale locale;

  final _pages = <BookReaderPageLayout>[];
  late final List<BookReaderPageLayout> pages = UnmodifiableListView(_pages);
  var _fragments = <BookReaderBlockSlice>[];
  double _remainingHeight;
  int _blockIndex = 0;
  bool _isComplete = false;

  bool get isComplete => _isComplete;

  /// Whether the page holding [displayOffset] is final.
  bool covers(int displayOffset) =>
      _isComplete ||
      (_pages.isNotEmpty && _pages.last.sourceEnd > displayOffset);

  /// Lays out blocks until the chapter ends, [budget] runs out, or — when
  /// given — the page with [targetOffset] and [minPageCount] pages exist.
  void advance({Duration? budget, int? targetOffset, int minPageCount = 0}) {
    if (_isComplete) return;
    final clock = Stopwatch()..start();
    final blocks = document.blocks;
    final hasTarget = targetOffset != null || minPageCount > 0;
    while (_blockIndex < blocks.length) {
      if (hasTarget &&
          (targetOffset == null || covers(targetOffset)) &&
          _pages.length >= minPageCount) {
        return;
      }
      if (budget != null && clock.elapsed >= budget) return;
      _layoutBlock(blocks[_blockIndex++]);
    }
    _finishPage();
    if (_pages.isEmpty) {
      _pages.add(
        const BookReaderPageLayout(fragments: [], sourceStart: 0, sourceEnd: 0),
      );
    }
    _isComplete = true;
  }

  void _finishPage() {
    if (_fragments.isEmpty) return;
    _pages.add(
      BookReaderPageLayout(
        fragments: List.unmodifiable(_fragments),
        sourceStart: _fragments.first.sourceStart,
        sourceEnd: _fragments.last.sourceEnd,
      ),
    );
    _fragments = <BookReaderBlockSlice>[];
    _remainingHeight = metrics.contentHeight;
  }

  void _layoutBlock(BookReaderBlock block) {
    if (block.type == BookReaderBlockType.pageBreak) {
      _finishPage();
      return;
    }
    if (!block.isText) {
      final height = _embedHeight(block);
      if (_fragments.isNotEmpty && height > _remainingHeight) _finishPage();
      final fittedHeight = math.min(height, _remainingHeight).toDouble();
      _fragments.add(
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
      _remainingHeight -= fittedHeight;
      if (_remainingHeight < 1) _finishPage();
      return;
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
      prefix: prefix,
      width: availableWidth,
    );
    final lineMetrics = blockPainter.computeLineMetrics();
    final lineEnds = <int>[];
    final remainingLineHeights = List<double>.filled(lineMetrics.length + 1, 0);
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
    blockPainter.dispose();
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
      final fullHeight = topSpacing + fullTextHeight + typography.bottomSpacing;
      if (fullHeight <= _remainingHeight + 0.5) {
        _fragments.add(
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
        _remainingHeight -= fullHeight;
        break;
      }

      final availableTextHeight = _remainingHeight - topSpacing;
      var fittingLineCount = 0;
      var contentHeight = 0.0;
      for (var index = lineIndex; index < lineMetrics.length; index++) {
        final nextHeight = contentHeight + lineMetrics[index].height;
        if (nextHeight > availableTextHeight + 0.5) break;
        contentHeight = nextHeight;
        fittingLineCount++;
      }
      if (fittingLineCount == 0 && _fragments.isNotEmpty) {
        _finishPage();
        continue;
      }
      if (textLength == 0) {
        final height = math
            .min(_remainingHeight, topSpacing + emptyHeight)
            .toDouble();
        _fragments.add(
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
        _remainingHeight -= height;
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
          .min(_remainingHeight, topSpacing + contentHeight + bottomSpacing)
          .toDouble();
      _fragments.add(
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
      _remainingHeight -= totalHeight;
      localStart = localEnd;
      lineIndex = lastLineIndex + 1;
      firstFragment = false;
      if (localStart < textLength) _finishPage();
    } while (localStart < textLength || textLength == 0 && firstFragment);
  }

  TextPainter _textPainter({
    required BookReaderBlock block,
    required BookReaderBlockTypography typography,
    required String prefix,
    required double width,
  }) => TextPainter(
    text: textSpanForRange(
      block,
      typography,
      localStart: 0,
      localEnd: block.text.length,
      prefix: prefix,
    ),
    textAlign: typography.textAlign,
    textDirection: typography.textDirection,
    textScaler: TextScaler.noScaling,
    locale: locale,
  )..layout(maxWidth: width);

  double _embedHeight(BookReaderBlock block) {
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
          width.round() == other.width.round() &&
          height.round() == other.height.round() &&
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
