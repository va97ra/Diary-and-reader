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

  test('adds and removes a bookmark at the current location', () {
    final added = BookReaderAnnotationActions.toggleBookmark(
      annotations: BookReaderAnnotations(),
      section: section,
      sectionProgress: 0.4,
    );

    expect(added.bookmarks, hasLength(1));
    expect(added.bookmarks.single.sectionId, section.id);

    final removed = BookReaderAnnotationActions.toggleBookmark(
      annotations: added,
      section: section,
      sectionProgress: 0.41,
    );

    expect(removed.bookmarks, isEmpty);
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
