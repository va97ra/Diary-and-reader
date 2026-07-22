import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
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

    return Stack(
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
              onPressed: previous == null
                  ? onPreviousSection
                  : () => onSelectPage(previous),
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
              onPressed: next == null
                  ? onNextSection
                  : () => onSelectPage(next),
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }
}
