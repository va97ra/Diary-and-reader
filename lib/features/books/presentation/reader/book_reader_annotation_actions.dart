import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_text_selection.dart';

abstract final class BookReaderAnnotationActions {
  /// The bookmark on the part of the chapter in sight: from
  /// [sectionProgress], the start of the page or screen, up to [visibleEnd],
  /// where the next page starts. Without the end only a bookmark right at
  /// the start counts.
  ///
  /// A fixed share of the chapter used to count instead, which in a long
  /// chapter spans several pages: a bookmark on the next page then took the
  /// previous one away instead of adding a second.
  static BookReaderBookmark? bookmarkAt({
    required BookReaderAnnotations annotations,
    required String sectionId,
    required double sectionProgress,
    double? visibleEnd,
  }) {
    const tolerance = 1e-6;
    bool inSight(double at) {
      final end = visibleEnd;
      if (end == null || end <= sectionProgress + tolerance) {
        return (at - sectionProgress).abs() < tolerance;
      }
      return at >= sectionProgress - tolerance &&
          (at < end - tolerance || end >= 1);
    }

    return annotations.bookmarks
        .where(
          (bookmark) =>
              bookmark.sectionId == sectionId &&
              inSight(bookmark.sectionProgress),
        )
        .firstOrNull;
  }

  /// The bookmarks in reading order, numbered from one as their flags on
  /// the page show them.
  static List<(BookReaderBookmark, int)> numberedBookmarks(
    BookReaderAnnotations annotations,
    List<BookSection> sections,
  ) {
    final order = {
      for (final (index, section) in sections.indexed) section.id: index,
    };
    final sorted = [...annotations.bookmarks]
      ..sort((a, b) {
        final bySection = (order[a.sectionId] ?? sections.length).compareTo(
          order[b.sectionId] ?? sections.length,
        );
        return bySection != 0
            ? bySection
            : a.sectionProgress.compareTo(b.sectionProgress);
      });
    return [
      for (final (index, bookmark) in sorted.indexed) (bookmark, index + 1),
    ];
  }

  /// Takes away the bookmark in sight, or puts one at [sectionProgress].
  static BookReaderAnnotations toggleBookmark({
    required BookReaderAnnotations annotations,
    required BookSection section,
    required double sectionProgress,
    double? visibleEnd,
  }) {
    final current = bookmarkAt(
      annotations: annotations,
      sectionId: section.id,
      sectionProgress: sectionProgress,
      visibleEnd: visibleEnd,
    );
    if (current != null) return annotations.removeBookmark(current.id);
    return annotations.addBookmark(
      BookReaderBookmark.create(
        sectionId: section.id,
        sectionProgress: sectionProgress,
        excerpt: excerpt(section: section, sectionProgress: sectionProgress),
      ),
    );
  }

  static BookReaderAnnotations addHighlight({
    required BookReaderAnnotations annotations,
    required String sectionId,
    required BookReaderTextSelection selection,
    required BookReaderHighlightColor color,
  }) => annotations.addHighlight(
    BookReaderHighlight.create(
      sectionId: sectionId,
      sectionProgress: selection.sectionProgress,
      startOffset: selection.startOffset,
      endOffset: selection.endOffset,
      excerpt: selection.text,
      color: color,
    ),
  );

  static BookReaderAnnotations addQuote({
    required BookReaderAnnotations annotations,
    required String sectionId,
    required BookReaderTextSelection selection,
  }) => annotations.addQuote(
    BookReaderQuote.create(
      sectionId: sectionId,
      sectionProgress: selection.sectionProgress,
      startOffset: selection.startOffset,
      endOffset: selection.endOffset,
      text: selection.text,
    ),
  );

  static String excerpt({
    required BookSection section,
    required double sectionProgress,
  }) {
    final text = richDocumentPlainText(
      section.content,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return section.title;
    const length = 72;
    final center = (text.length * sectionProgress).round();
    final start = (center - length ~/ 2).clamp(0, text.length);
    final end = (start + length).clamp(0, text.length);
    return '${start > 0 ? '…' : ''}'
        '${text.substring(start, end)}'
        '${end < text.length ? '…' : ''}';
  }
}
