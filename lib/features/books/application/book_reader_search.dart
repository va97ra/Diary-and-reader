import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';

class BookReaderSearchResult {
  const BookReaderSearchResult({
    required this.sectionId,
    required this.sectionTitle,
    required this.offset,
    required this.sectionProgress,
    required this.excerpt,
  });

  final String sectionId;
  final String sectionTitle;
  final int offset;
  final double sectionProgress;
  final String excerpt;
}

abstract final class BookReaderSearch {
  static List<BookReaderSearchResult> find(
    Iterable<BookSection> sections,
    String query, {
    int limit = 50,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.length < 2 || limit <= 0) return const [];
    final results = <BookReaderSearchResult>[];

    for (final section in sections) {
      if (section.title.toLowerCase().contains(normalizedQuery)) {
        results.add(
          BookReaderSearchResult(
            sectionId: section.id,
            sectionTitle: section.title,
            offset: 0,
            sectionProgress: 0,
            excerpt: section.title,
          ),
        );
        if (results.length >= limit) break;
      }
      final text = richDocumentPlainText(section.content);
      final lowerText = text.toLowerCase();
      var start = 0;
      while (results.length < limit) {
        final offset = lowerText.indexOf(normalizedQuery, start);
        if (offset < 0) break;
        results.add(
          BookReaderSearchResult(
            sectionId: section.id,
            sectionTitle: section.title,
            offset: offset,
            sectionProgress: text.length <= 1
                ? 0
                : (offset / (text.length - 1)).clamp(0, 1),
            excerpt: _excerpt(text, offset, normalizedQuery.length),
          ),
        );
        start = offset + normalizedQuery.length;
      }
      if (results.length >= limit) break;
    }
    return results;
  }

  static String _excerpt(String text, int offset, int matchLength) {
    const radius = 48;
    final start = (offset - radius).clamp(0, text.length);
    final end = (offset + matchLength + radius).clamp(0, text.length);
    final content = text
        .substring(start, end)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${start > 0 ? '…' : ''}$content${end < text.length ? '…' : ''}';
  }
}
