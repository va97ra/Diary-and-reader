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
import 'package:flutter/rendering.dart';

/// Reports and changes the reading position of a [BookReaderContinuousView]
/// in display text offsets, independent of how much of the chapter is built.
class BookReaderContinuousController {
  _BookReaderContinuousViewState? _state;

  /// Display offset of the text at the top of the viewport.
  int? get topOffset => _state?._topOffset();

  /// Scrolls [displayOffset] to the top unless it is already on screen.
  void reveal(int displayOffset) => _state?._reveal(displayOffset);
}

/// Scrolling chapter view that builds and paints only the visible blocks, so
/// opening and scrolling cost the same for short and very long chapters.
///
/// The list is anchored at a block: blocks after it grow downwards, blocks
/// before it grow upwards. Jumping to any position re-anchors the list
/// instead of estimating pixel offsets of unbuilt blocks.
class BookReaderContinuousView extends StatefulWidget {
  const BookReaderContinuousView({
    required this.sectionId,
    required this.document,
    required this.settings,
    required this.palette,
    required this.assets,
    required this.scrollController,
    required this.controller,
    required this.initialDisplayOffset,
    required this.edgeInsets,
    required this.highlights,
    required this.selectionGeneration,
    required this.onSelectionChanged,
    required this.onPointerDown,
    required this.onPointerUp,
    required this.onPointerMove,
    required this.onPointerSignal,
    required this.onPointerCancel,
    required this.onUserScroll,
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
  final BookReaderContinuousController controller;

  /// Position shown when the view or its [document] is (re)created.
  final int initialDisplayOffset;

  /// Extra room at the start and end of the chapter, left for panels that
  /// float above the text.
  final EdgeInsets edgeInsets;
  final List<BookReaderRenderHighlight> highlights;
  final int selectionGeneration;
  final ValueChanged<TextSelection?> onSelectionChanged;
  final PointerDownEventListener onPointerDown;
  final PointerUpEventListener onPointerUp;
  final PointerMoveEventListener onPointerMove;
  final void Function(PointerSignalEvent) onPointerSignal;
  final PointerCancelEventListener onPointerCancel;
  final VoidCallback onUserScroll;
  final bool speechTargetMode;
  final BookReaderTextRange? speechRange;
  final ValueChanged<int>? onSpeechTargetSelected;

  @override
  State<BookReaderContinuousView> createState() =>
      _BookReaderContinuousViewState();
}

class _BookReaderContinuousViewState extends State<BookReaderContinuousView> {
  static const _anchorKey = ValueKey('reader-continuous-anchor');

  final _viewportKey = GlobalKey();
  final _items = <int, _ContinuousBlockItemState>{};
  int _anchorIndex = 0;
  double _contentWidth = 1;

  /// Part of the anchor block scrolled past; applied once it is laid out.
  double _anchorFraction = 0;

  List<BookReaderBlock> get _blocks => widget.document.blocks;

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    _anchorAt(widget.initialDisplayOffset);
  }

  @override
  void didUpdateWidget(covariant BookReaderContinuousView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      if (identical(oldWidget.controller._state, this)) {
        oldWidget.controller._state = null;
      }
      widget.controller._state = this;
    }
    if (!identical(oldWidget.document, widget.document)) {
      _anchorAt(widget.initialDisplayOffset);
      _jumpToAnchor();
    }
  }

  @override
  void dispose() {
    if (identical(widget.controller._state, this)) {
      widget.controller._state = null;
    }
    super.dispose();
  }

  int _blockIndexFor(int displayOffset) {
    var low = 0;
    var high = _blocks.length - 1;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (_blocks[middle].sourceStart <= displayOffset) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
  }

  double _fractionInBlock(int index, int displayOffset) {
    final block = _blocks[index];
    final length = block.isText ? block.text.length : 0;
    if (length <= 0) return 0;
    return ((displayOffset - block.sourceStart) / length).clamp(0, 1);
  }

  void _anchorAt(int displayOffset) {
    if (_blocks.isEmpty) {
      _anchorIndex = 0;
      _anchorFraction = 0;
      return;
    }
    _anchorIndex = _blockIndexFor(displayOffset);
    _anchorFraction = _fractionInBlock(_anchorIndex, displayOffset);
    _scheduleAnchorCorrection();
  }

  void _jumpToAnchor() {
    final controller = widget.scrollController;
    if (controller.hasClients) controller.jumpTo(0);
  }

  void _scheduleAnchorCorrection() {
    if (_anchorFraction <= 0) return;
    final anchor = _anchorIndex;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        final fraction = _anchorFraction;
        _anchorFraction = 0;
        if (!mounted || anchor != _anchorIndex) return;
        final box = _items[anchor]?.context.findRenderObject();
        final controller = widget.scrollController;
        if (box is! RenderBox || !box.hasSize || !controller.hasClients) {
          return;
        }
        final position = controller.position;
        position.jumpTo(
          (box.size.height * fraction).clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
      })
      ..scheduleFrame();
  }

  RenderBox? get _viewport {
    final viewport = _viewportKey.currentContext?.findRenderObject();
    return viewport is RenderBox && viewport.hasSize ? viewport : null;
  }

  /// Vertical span of a built block relative to the viewport.
  ({double top, double height})? _blockSpan(int index, RenderBox viewport) {
    final box = _items[index]?.context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return (
      top: box.localToGlobal(Offset.zero, ancestor: viewport).dy,
      height: box.size.height,
    );
  }

  int? _topOffset() {
    final viewport = _viewport;
    if (viewport == null || _blocks.isEmpty) return null;
    int? topIndex;
    var topSpan = (top: 0.0, height: 0.0);
    for (final index in _items.keys) {
      final span = _blockSpan(index, viewport);
      if (span == null || span.top + span.height <= 0.5) continue;
      if (topIndex == null || span.top < topSpan.top) {
        topIndex = index;
        topSpan = span;
      }
    }
    if (topIndex == null) return null;
    final block = _blocks[topIndex];
    final length = block.isText ? block.text.length : 0;
    final scrolledPast = topSpan.height <= 0
        ? 0.0
        : (-topSpan.top / topSpan.height).clamp(0.0, 1.0);
    return block.sourceStart + (length * scrolledPast).round();
  }

  void _reveal(int displayOffset) {
    if (_blocks.isEmpty) return;
    final index = _blockIndexFor(displayOffset);
    final viewport = _viewport;
    final span = viewport == null ? null : _blockSpan(index, viewport);
    if (viewport != null && span != null) {
      final y = span.top + span.height * _fractionInBlock(index, displayOffset);
      if (y >= 0 && y <= viewport.size.height * 0.8) return;
    }
    setState(() => _anchorAt(displayOffset));
    _jumpToAnchor();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const ValueKey('reader-continuous-view'),
    color: widget.palette.background,
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              widget.settings.contentWidth +
              widget.settings.horizontalPadding * 2,
        ),
        child: Container(
          key: const ValueKey('reader-surface'),
          width: double.infinity,
          height: double.infinity,
          color: widget.palette.surface,
          child: Listener(
            onPointerDown: widget.onPointerDown,
            onPointerUp: widget.onPointerUp,
            onPointerMove: widget.onPointerMove,
            onPointerSignal: widget.onPointerSignal,
            onPointerCancel: widget.onPointerCancel,
            child: LayoutBuilder(
              builder: (context, constraints) {
                _contentWidth = math.max(
                  1,
                  constraints.maxWidth - widget.settings.horizontalPadding * 2,
                );
                return NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    if (notification.direction != ScrollDirection.idle) {
                      widget.onUserScroll();
                    }
                    return false;
                  },
                  child: KeyedSubtree(
                    key: _viewportKey,
                    child: CustomScrollView(
                      key: ValueKey('reader-document-${widget.sectionId}'),
                      controller: widget.scrollController,
                      center: _anchorKey,
                      slivers: [
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildItem(_anchorIndex - 1 - index),
                            childCount: _anchorIndex,
                          ),
                        ),
                        SliverList(
                          key: _anchorKey,
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildItem(_anchorIndex + index),
                            childCount: _blocks.length - _anchorIndex,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildItem(int index) {
    final block = _blocks[index];
    final settings = widget.settings;
    return _ContinuousBlockItem(
      key: ValueKey('reader-block-$index'),
      index: index,
      items: _items,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          settings.horizontalPadding,
          index == 0 ? settings.verticalPadding + widget.edgeInsets.top : 0,
          settings.horizontalPadding,
          index == _blocks.length - 1
              ? settings.verticalPadding + widget.edgeInsets.bottom
              : 0,
        ),
        child: BookReaderFragmentView(
          key: ValueKey(
            'reader-fragment-${block.sourceStart}-0-'
            '${widget.selectionGeneration}',
          ),
          fragment: _fragmentFor(block),
          settings: settings,
          palette: widget.palette,
          assets: widget.assets,
          highlights: widget.highlights,
          selectionGeneration: widget.selectionGeneration,
          onSelectionChanged: widget.onSelectionChanged,
          speechTargetMode: widget.speechTargetMode,
          speechRange: widget.speechRange,
          onSpeechTargetSelected: widget.onSpeechTargetSelected,
          constrainToMeasuredHeight: false,
        ),
      ),
    );
  }

  BookReaderBlockSlice _fragmentFor(BookReaderBlock block) {
    if (block.isText) {
      final typography = BookReaderTypography.block(
        block,
        widget.settings,
        widget.palette,
      );
      return BookReaderBlockSlice(
        block: block,
        localStart: 0,
        localEnd: block.text.length,
        topSpacing: typography.topSpacing,
        bottomSpacing: typography.bottomSpacing,
        contentHeight: 0,
        totalHeight: 0,
      );
    }
    final height = switch (block.type) {
      BookReaderBlockType.image => _imageHeight(block),
      BookReaderBlockType.pageBreak => 8.0,
      _ => 72.0,
    };
    return BookReaderBlockSlice(
      block: block,
      localStart: 0,
      localEnd: 0,
      topSpacing: 0,
      bottomSpacing: 0,
      contentHeight: height,
      totalHeight: height,
      embedHeight: height,
    );
  }

  double _imageHeight(BookReaderBlock block) {
    final width = _contentWidth * block.imageWidthPercent.clamp(20, 100) / 100;
    final captionHeight = block.imageCaption.isEmpty ? 0.0 : 42.0;
    return (width * 0.72 + captionHeight + 24).clamp(120, 440).toDouble();
  }
}

/// Registers a built block so the view can find which one is on screen.
class _ContinuousBlockItem extends StatefulWidget {
  const _ContinuousBlockItem({
    required this.index,
    required this.items,
    required this.child,
    super.key,
  });

  final int index;
  final Map<int, _ContinuousBlockItemState> items;
  final Widget child;

  @override
  State<_ContinuousBlockItem> createState() => _ContinuousBlockItemState();
}

class _ContinuousBlockItemState extends State<_ContinuousBlockItem> {
  @override
  void initState() {
    super.initState();
    widget.items[widget.index] = this;
  }

  @override
  void didUpdateWidget(covariant _ContinuousBlockItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index || oldWidget.items != widget.items) {
      _unregister(oldWidget);
      widget.items[widget.index] = this;
    }
  }

  @override
  void dispose() {
    _unregister(widget);
    super.dispose();
  }

  void _unregister(_ContinuousBlockItem item) {
    if (identical(item.items[item.index], this)) item.items.remove(item.index);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
