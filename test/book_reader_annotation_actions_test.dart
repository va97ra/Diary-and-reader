import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_annotation_actions.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_text_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final project = BookProject.create(
    title: 'Книга',
    chapterTitle: 'Глава',
    languageCode: 'ru',
  );
  final section = project.activeSection!;

  test('adds and removes a bookmark on the page in sight', () {
    final added = BookReaderAnnotationActions.toggleBookmark(
      annotations: BookReaderAnnotations(),
      section: section,
      sectionProgress: 0.4,
      visibleEnd: 0.41,
    );

    expect(added.bookmarks, hasLength(1));
    expect(added.bookmarks.single.sectionId, section.id);

    final removed = BookReaderAnnotationActions.toggleBookmark(
      annotations: added,
      section: section,
      sectionProgress: 0.4,
      visibleEnd: 0.41,
    );

    expect(removed.bookmarks, isEmpty);
  });

  test('the next page takes a bookmark of its own', () {
    // Pages of a long chapter, each about one percent of it.
    var annotations = BookReaderAnnotations();
    for (final (start, end) in [(0.40, 0.41), (0.41, 0.42), (0.42, 0.43)]) {
      annotations = BookReaderAnnotationActions.toggleBookmark(
        annotations: annotations,
        section: section,
        sectionProgress: start,
        visibleEnd: end,
      );
    }

    expect(annotations.bookmarks, hasLength(3));
    // Back on the middle page, its bookmark is the one in sight.
    expect(
      BookReaderAnnotationActions.bookmarkAt(
        annotations: annotations,
        sectionId: section.id,
        sectionProgress: 0.41,
        visibleEnd: 0.42,
      )?.sectionProgress,
      0.41,
    );
    // After the text reflowed, a page that holds a bookmark shows it.
    expect(
      BookReaderAnnotationActions.bookmarkAt(
        annotations: annotations,
        sectionId: section.id,
        sectionProgress: 0.405,
        visibleEnd: 0.425,
      ),
      isNotNull,
    );
  });

  test('creates a highlight and quote from the same selection', () {
    const selection = BookReaderTextSelection(
      startOffset: 2,
      endOffset: 8,
      text: 'цитата',
      sectionProgress: 0.25,
    );

    final highlighted = BookReaderAnnotationActions.addHighlight(
      annotations: BookReaderAnnotations(),
      sectionId: section.id,
      selection: selection,
      color: BookReaderHighlightColor.green,
    );
    final quoted = BookReaderAnnotationActions.addQuote(
      annotations: highlighted,
      sectionId: section.id,
      selection: selection,
    );

    expect(quoted.highlights.single.excerpt, selection.text);
    expect(quoted.highlights.single.color, BookReaderHighlightColor.green);
    expect(quoted.quotes.single.text, selection.text);
  });
}
