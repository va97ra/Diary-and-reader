import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_text_selection.dart';

abstract final class BookReaderAnnotationActions {
  static BookReaderBookmark? bookmarkAt({
    required BookReaderAnnotations annotations,
    required String sectionId,
    required double sectionProgress,
  }) => annotations.bookmarks
      .where(
        (bookmark) =>
            bookmark.sectionId == sectionId &&
            (bookmark.sectionProgress - sectionProgress).abs() < 0.02,
      )
      .firstOrNull;

  static BookReaderAnnotations toggleBookmark({
    required BookReaderAnnotations annotations,
    required BookSection section,
    required double sectionProgress,
  }) {
    final current = bookmarkAt(
      annotations: annotations,
      sectionId: section.id,
      sectionProgress: sectionProgress,
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
