import 'dart:math' as math;

import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:flutter/material.dart';

class BookEditorPageStage extends StatelessWidget {
  const BookEditorPageStage({
    required this.constraints,
    required this.pageFormat,
    required this.pageIndices,
    required this.previousPage,
    required this.nextPage,
    required this.pageBuilder,
    required this.onSelectPage,
    required this.onExitCompactPreview,
    this.compact = false,
    super.key,
  });

  final BoxConstraints constraints;
  final BookPageFormat pageFormat;
  final List<int> pageIndices;
  final int? previousPage;
  final int? nextPage;
  final Widget Function(int pageIndex, double scale) pageBuilder;
  final ValueChanged<int> onSelectPage;
  final VoidCallback onExitCompactPreview;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = compact ? 24.0 : 76.0;
    final verticalPadding = compact ? 24.0 : 36.0;
    final compactControlsHeight = compact ? 64.0 : 0.0;
    const pageGap = 18.0;
    final naturalWidth =
        pageFormat.width * pageIndices.length +
        pageGap * (pageIndices.length - 1);
    final widthScale =
        (constraints.maxWidth - horizontalPadding) / naturalWidth;
    final heightScale =
        (constraints.maxHeight - verticalPadding - compactControlsHeight) /
        pageFormat.height;
    final scale = math
        .min(1, math.min(widthScale, heightScale))
        .clamp(0.1, 1.0)
        .toDouble();
    final strings = AppStrings.of(context);
    final pages = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < pageIndices.length; index++) ...[
          if (index > 0) const SizedBox(width: pageGap),
          IgnorePointer(
            ignoring: compact,
            child: pageBuilder(pageIndices[index], scale),
          ),
        ],
      ],
    );

    return Stack(
      children: [
        if (compact)
          Positioned.fill(
            bottom: compactControlsHeight,
            child: Center(child: pages),
          )
        else
          Center(child: pages),
        if (compact)
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (previousPage case final page?)
                  IconButton.filledTonal(
                    key: const ValueKey('book-page-previous'),
                    tooltip: strings.previousPage,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onSelectPage(page),
                    icon: const Icon(Icons.chevron_left),
                  ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  key: const ValueKey('mobile-a4-edit-button'),
                  onPressed: onExitCompactPreview,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(strings.comfortableWriting),
                ),
                const SizedBox(width: 12),
                if (nextPage case final page?)
                  IconButton.filledTonal(
                    key: const ValueKey('book-page-next'),
                    tooltip: strings.nextPage,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => onSelectPage(page),
                    icon: const Icon(Icons.chevron_right),
                  ),
              ],
            ),
          )
        else ...[
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filledTonal(
                key: const ValueKey('book-page-previous'),
                tooltip: strings.previousPage,
                onPressed: previousPage == null
                    ? null
                    : () => onSelectPage(previousPage!),
                icon: const Icon(Icons.chevron_left),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filledTonal(
                key: const ValueKey('book-page-next'),
                tooltip: strings.nextPage,
                onPressed: nextPage == null
                    ? null
                    : () => onSelectPage(nextPage!),
                icon: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
