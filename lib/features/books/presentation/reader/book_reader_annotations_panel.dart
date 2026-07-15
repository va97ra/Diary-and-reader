import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_highlight_style.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_location_callback.dart';
import 'package:flutter/material.dart';

class BookReaderAnnotationsPanel extends StatelessWidget {
  const BookReaderAnnotationsPanel({
    required this.highlights,
    required this.quotes,
    required this.sections,
    required this.onSelected,
    required this.onHighlightColorChanged,
    required this.onDeleteHighlight,
    required this.onDeleteQuote,
    super.key,
  });

  final List<BookReaderHighlight> highlights;
  final List<BookReaderQuote> quotes;
  final List<BookSection> sections;
  final BookReaderLocationCallback onSelected;
  final void Function(
    BookReaderHighlight highlight,
    BookReaderHighlightColor color,
  )
  onHighlightColorChanged;
  final ValueChanged<BookReaderHighlight> onDeleteHighlight;
  final ValueChanged<BookReaderQuote> onDeleteQuote;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (highlights.isEmpty && quotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(strings.noHighlights, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return ListView(
      key: const ValueKey('reader-annotations'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (highlights.isNotEmpty) ...[
          _Header(strings.highlights),
          for (final highlight in highlights)
            ListTile(
              leading: Icon(
                Icons.circle,
                color: BookReaderHighlightStyle.displayColor(highlight.color),
              ),
              title: Text(
                highlight.excerpt,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _locationLabel(
                  sections,
                  highlight.sectionId,
                  highlight.sectionProgress,
                ),
              ),
              trailing: PopupMenuButton<Object>(
                tooltip: strings.highlightActions,
                onSelected: (value) {
                  if (value is BookReaderHighlightColor) {
                    onHighlightColorChanged(highlight, value);
                  } else if (value == _deleteHighlight) {
                    onDeleteHighlight(highlight);
                  }
                },
                itemBuilder: (_) => [
                  for (final color in BookReaderHighlightColor.values)
                    PopupMenuItem(
                      value: color,
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            color: BookReaderHighlightStyle.displayColor(color),
                          ),
                          const SizedBox(width: 12),
                          Text(_highlightColorName(strings, color)),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: _deleteHighlight,
                    child: Text(strings.deleteHighlight),
                  ),
                ],
              ),
              onTap: () =>
                  onSelected(highlight.sectionId, highlight.sectionProgress),
            ),
        ],
        if (quotes.isNotEmpty) ...[
          _Header(strings.quotes),
          for (final quote in quotes)
            ListTile(
              leading: const Icon(Icons.format_quote),
              title: Text(
                quote.text,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _locationLabel(
                  sections,
                  quote.sectionId,
                  quote.sectionProgress,
                ),
              ),
              trailing: IconButton(
                tooltip: strings.deleteQuote,
                onPressed: () => onDeleteQuote(quote),
                icon: const Icon(Icons.delete_outline),
              ),
              onTap: () => onSelected(quote.sectionId, quote.sectionProgress),
            ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

String _locationLabel(
  List<BookSection> sections,
  String sectionId,
  double progress,
) {
  final title = sections
      .where((section) => section.id == sectionId)
      .firstOrNull
      ?.title;
  return '${title ?? '—'} · ${(progress * 100).round()}%';
}

const _deleteHighlight = 'delete-highlight';

String _highlightColorName(
  AppStrings strings,
  BookReaderHighlightColor color,
) => switch (color) {
  BookReaderHighlightColor.yellow => strings.yellowHighlight,
  BookReaderHighlightColor.green => strings.greenHighlight,
  BookReaderHighlightColor.blue => strings.blueHighlight,
  BookReaderHighlightColor.pink => strings.pinkHighlight,
};
