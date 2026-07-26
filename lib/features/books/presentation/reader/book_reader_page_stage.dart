import 'package:dnevnik/core/l10n/app_strings.dart';
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
    super.key,
  });

  final int activePage;
  final int pageCount;
  final BookReaderViewMode viewMode;
  final Widget Function(int pageIndex) pageBuilder;
  final ValueChanged<int> onSelectPage;
  final VoidCallback? onPreviousSection;
  final VoidCallback? onNextSection;

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
    final strings = AppStrings.of(context);

    final backward = previous == null
        ? onPreviousSection
        : () => onSelectPage(previous);
    final forward = next == null ? onNextSection : () => onSelectPage(next);

    return _ReaderPagedInput(
      onBackward: backward,
      onForward: forward,
      child: Stack(
        children: [
          Center(
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
          Positioned(
            left: 6,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filledTonal(
                key: const ValueKey('reader-previous-page'),
                tooltip: strings.previousReaderPage,
                onPressed: backward,
                icon: const Icon(Icons.chevron_left),
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filledTonal(
                key: const ValueKey('reader-next-page'),
                tooltip: strings.nextReaderPage,
                onPressed: forward,
                icon: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderPagedInput extends StatefulWidget {
  const _ReaderPagedInput({
    required this.onBackward,
    required this.onForward,
    required this.child,
  });

  final VoidCallback? onBackward;
  final VoidCallback? onForward;
  final Widget child;

  @override
  State<_ReaderPagedInput> createState() => _ReaderPagedInputState();
}

class _ReaderPagedInputState extends State<_ReaderPagedInput> {
  bool _locked = false;

  void _move(VoidCallback? action) {
    if (_locked || action == null) return;
    _locked = true;
    action();
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) _locked = false;
    });
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta > 0) _move(widget.onForward);
    if (delta < 0) _move(widget.onBackward);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: _handlePointerSignal,
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -220) _move(widget.onForward);
        if (velocity > 220) _move(widget.onBackward);
      },
      child: widget.child,
    ),
  );
}
