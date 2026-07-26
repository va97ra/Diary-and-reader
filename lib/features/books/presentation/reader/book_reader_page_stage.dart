import 'dart:math' as math;

import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class BookReaderPageStage extends StatelessWidget {
  const BookReaderPageStage({
    required this.activePage,
    required this.pageCount,
    required this.viewMode,
    required this.pageBuilder,
    required this.onSelectPage,
    required this.onPreviousSection,
    required this.onNextSection,
    required this.isPaginating,
    super.key,
  });

  final int activePage;
  final int pageCount;
  final BookReaderViewMode viewMode;
  final Widget Function(int pageIndex) pageBuilder;
  final ValueChanged<int> onSelectPage;
  final VoidCallback? onPreviousSection;
  final VoidCallback? onNextSection;
  final bool isPaginating;

  @override
  Widget build(BuildContext context) {
    final isSpread = viewMode == BookReaderViewMode.spread;
    final firstPage = isSpread ? (activePage ~/ 2) * 2 : activePage;
    final indices = [
      firstPage,
      if (isSpread && firstPage + 1 < pageCount) firstPage + 1,
    ];
    final previous = firstPage > 0 ? firstPage - (isSpread ? 2 : 1) : null;
    final next = firstPage + (isSpread ? 2 : 1) < pageCount
        ? firstPage + (isSpread ? 2 : 1)
        : null;
    final backward = previous == null
        ? onPreviousSection
        : () => onSelectPage(previous);
    final forward = next == null
        ? (isPaginating ? null : onNextSection)
        : () => onSelectPage(next);

    return _ReaderPagedInput(
      pageKey: ValueKey('reader-page-set-$firstPage'),
      onBackward: backward,
      onForward: forward,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < indices.length; index++) ...[
              if (index > 0) const SizedBox(width: 16),
              pageBuilder(indices[index]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReaderPagedInput extends StatefulWidget {
  const _ReaderPagedInput({
    required this.pageKey,
    required this.onBackward,
    required this.onForward,
    required this.child,
  });

  final Key pageKey;
  final VoidCallback? onBackward;
  final VoidCallback? onForward;
  final Widget child;

  @override
  State<_ReaderPagedInput> createState() => _ReaderPagedInputState();
}

class _ReaderPagedInputState extends State<_ReaderPagedInput> {
  bool _locked = false;
  bool _dragging = false;
  double _dragOffset = 0;
  int _transitionDirection = 1;
  int? _pointer;

  void _move(VoidCallback? action, {required int direction}) {
    if (_locked || action == null) {
      setState(() {
        _dragging = false;
        _dragOffset = 0;
      });
      return;
    }
    _locked = true;
    setState(() {
      _transitionDirection = direction;
      _dragging = false;
      _dragOffset = 0;
    });
    action();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _locked = false;
    });
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta > 0) _move(widget.onForward, direction: 1);
    if (delta < 0) _move(widget.onBackward, direction: -1);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_locked || _pointer != null) return;
    _pointer = event.pointer;
    _dragging = true;
    _dragOffset = 0;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_locked || event.pointer != _pointer) return;
    final width = context.size?.width ?? 1;
    setState(() {
      _dragging = true;
      _dragOffset = (_dragOffset + event.delta.dx)
          .clamp(-width, width)
          .toDouble();
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    if (_locked) return;
    final width = context.size?.width ?? 1;
    final shouldMove = _dragOffset.abs() >= math.max(48, width * 0.16);
    if (!shouldMove) {
      setState(() {
        _dragging = false;
        _dragOffset = 0;
      });
      return;
    }
    if (_dragOffset < 0) {
      _move(widget.onForward, direction: 1);
    } else {
      _move(widget.onBackward, direction: -1);
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    setState(() {
      _dragging = false;
      _dragOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: _handlePointerSignal,
    onPointerDown: _handlePointerDown,
    onPointerMove: _handlePointerMove,
    onPointerUp: _handlePointerUp,
    onPointerCancel: _handlePointerCancel,
    behavior: HitTestBehavior.translucent,
    child: KeyedSubtree(
      key: const ValueKey('reader-page-swipe-area'),
      child: AnimatedContainer(
        duration: _dragging ? Duration.zero : const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(_dragOffset, 0, 0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.center,
            children: [...previousChildren, ?currentChild],
          ),
          transitionBuilder: (child, animation) => AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) {
              final entering = animation.status != AnimationStatus.reverse;
              final remaining = 1 - animation.value;
              final direction = _transitionDirection.toDouble();
              final horizontalOffset = entering
                  ? remaining * direction
                  : -remaining * direction;
              final angle = entering
                  ? remaining * direction * 0.08
                  : -remaining * direction * 0.08;
              return Opacity(
                opacity: animation.value.clamp(0, 1),
                child: FractionalTranslation(
                  translation: Offset(horizontalOffset, 0),
                  child: Transform(
                    alignment: direction > 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: child,
                  ),
                ),
              );
            },
          ),
          child: KeyedSubtree(key: widget.pageKey, child: widget.child),
        ),
      ),
    ),
  );
}
