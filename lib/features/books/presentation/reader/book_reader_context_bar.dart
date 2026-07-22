import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:flutter/material.dart';

class BookReaderContextBar extends StatelessWidget {
  const BookReaderContextBar({
    required this.palette,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.isBookmarked,
    required this.onPrevious,
    required this.onContents,
    required this.onSettings,
    required this.onBookmark,
    required this.onNext,
    super.key,
  });

  final BookReaderPalette palette;
  final bool canGoPrevious;
  final bool canGoNext;
  final bool isBookmarked;
  final VoidCallback onPrevious;
  final VoidCallback onContents;
  final VoidCallback onSettings;
  final VoidCallback onBookmark;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Material(
      key: const ValueKey('reader-context-bar'),
      color: palette.surface,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _ReaderAction(
                key: const ValueKey('reader-previous-section'),
                label: strings.previousShort,
                semanticLabel: strings.previousSection,
                onPressed: canGoPrevious ? onPrevious : null,
                icon: const Icon(Icons.chevron_left),
              ),
              _ReaderAction(
                key: const ValueKey('reader-contents-action'),
                label: strings.contentsShort,
                onPressed: onContents,
                icon: const Icon(Icons.toc),
              ),
              _ReaderAction(
                key: const ValueKey('reader-settings-action'),
                label: strings.settings,
                onPressed: onSettings,
                icon: const Text(
                  'Aa',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                accent: true,
              ),
              _ReaderAction(
                key: const ValueKey('reader-bookmark-action'),
                label: strings.bookmark,
                onPressed: onBookmark,
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
              ),
              _ReaderAction(
                key: const ValueKey('reader-next-section'),
                label: strings.nextShort,
                semanticLabel: strings.nextSection,
                onPressed: canGoNext ? onNext : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderAction extends StatelessWidget {
  const _ReaderAction({
    required this.label,
    required this.onPressed,
    required this.icon,
    this.accent = false,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget icon;
  final bool accent;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final scheme = Theme.of(context).colorScheme;
    final color = !enabled
        ? Theme.of(context).disabledColor
        : accent
        ? scheme.primary
        : scheme.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: semanticLabel ?? label,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconTheme(
                  data: IconThemeData(size: 22, color: color),
                  child: icon,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
