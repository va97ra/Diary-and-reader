import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_highlight_style.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_text_selection.dart';
import 'package:flutter/material.dart';

class BookReaderSelectionBar extends StatelessWidget {
  const BookReaderSelectionBar({
    required this.selection,
    required this.onHighlight,
    required this.onSaveQuote,
    required this.onAddNote,
    required this.onCopy,
    required this.onDictionary,
    required this.onTranslate,
    required this.onWebSearch,
    required this.onClose,
    super.key,
  });

  final BookReaderTextSelection selection;
  final ValueChanged<BookReaderHighlightColor> onHighlight;
  final VoidCallback onSaveQuote;
  final VoidCallback onAddNote;
  final VoidCallback onCopy;
  final VoidCallback onDictionary;
  final VoidCallback onTranslate;
  final VoidCallback onWebSearch;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      top: false,
      child: Material(
        key: const ValueKey('reader-selection-bar'),
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final color in BookReaderHighlightColor.values)
                IconButton(
                  key: ValueKey('reader-highlight-${color.name}'),
                  tooltip: _highlightColorName(strings, color),
                  onPressed: () => onHighlight(color),
                  icon: DecoratedBox(
                    decoration: BoxDecoration(
                      color: BookReaderHighlightStyle.displayColor(color),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26),
                    ),
                    child: const SizedBox(width: 22, height: 22),
                  ),
                ),
              const SizedBox(width: 4),
              FilledButton.tonalIcon(
                key: const ValueKey('reader-save-quote'),
                onPressed: onSaveQuote,
                icon: const Icon(Icons.format_quote, size: 18),
                label: Text(strings.saveQuote),
              ),
              IconButton(
                key: const ValueKey('reader-note-selection'),
                tooltip: strings.addNoteToSelection,
                onPressed: onAddNote,
                icon: const Icon(Icons.note_add_outlined),
              ),
              IconButton(
                key: const ValueKey('reader-copy-selection'),
                tooltip: strings.copySelection,
                onPressed: onCopy,
                icon: const Icon(Icons.copy_outlined),
              ),
              IconButton(
                key: const ValueKey('reader-dictionary-selection'),
                tooltip: strings.dictionary,
                onPressed: onDictionary,
                icon: const Icon(Icons.menu_book_outlined),
              ),
              IconButton(
                key: const ValueKey('reader-translate-selection'),
                tooltip: strings.translate,
                onPressed: onTranslate,
                icon: const Icon(Icons.translate),
              ),
              IconButton(
                key: const ValueKey('reader-web-search-selection'),
                tooltip: strings.webSearch,
                onPressed: onWebSearch,
                icon: const Icon(Icons.travel_explore),
              ),
              IconButton(
                tooltip: strings.closeSelectionActions,
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _highlightColorName(
  AppStrings strings,
  BookReaderHighlightColor color,
) => switch (color) {
  BookReaderHighlightColor.yellow => strings.yellowHighlight,
  BookReaderHighlightColor.green => strings.greenHighlight,
  BookReaderHighlightColor.blue => strings.blueHighlight,
  BookReaderHighlightColor.pink => strings.pinkHighlight,
};
