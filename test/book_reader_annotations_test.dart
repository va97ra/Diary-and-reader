import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reader annotations round-trip and keep valid locations', () {
    final now = DateTime.utc(2026, 7, 14, 12);
    final bookmark = BookReaderBookmark.create(
      sectionId: 'chapter-1',
      sectionProgress: 2,
      excerpt: '  Фрагмент книги  ',
      now: now,
    );
    final note = BookReaderNote.create(
      sectionId: 'chapter-1',
      sectionProgress: 0.35,
      excerpt: 'Фрагмент книги',
      text: '  Проверить эту сцену  ',
      now: now,
    );
    final highlight = BookReaderHighlight.create(
      sectionId: 'chapter-1',
      sectionProgress: 0.2,
      startOffset: 5,
      endOffset: 18,
      excerpt: 'важный фрагмент',
      color: BookReaderHighlightColor.blue,
      now: now,
    );
    final quote = BookReaderQuote.create(
      sectionId: 'chapter-1',
      sectionProgress: 0.4,
      startOffset: 20,
      endOffset: 32,
      text: 'Точная цитата',
      now: now,
    );
    final annotations = BookReaderAnnotations(
      bookmarks: [bookmark],
      notes: [note],
      highlights: [highlight],
      quotes: [quote],
    );

    final restored = BookReaderAnnotations.fromJson(annotations.toJson());

    expect(restored.bookmarks.single.sectionProgress, 1);
    expect(restored.bookmarks.single.excerpt, 'Фрагмент книги');
    expect(restored.notes.single.text, 'Проверить эту сцену');
    expect(restored.notes.single.sectionProgress, 0.35);
    expect(restored.highlights.single.color, BookReaderHighlightColor.blue);
    expect(restored.highlights.single.startOffset, 5);
    expect(restored.quotes.single.text, 'Точная цитата');
  });

  test('reader annotations add, edit and remove immutable entries', () {
    final now = DateTime.utc(2026, 7, 14, 12);
    final bookmark = BookReaderBookmark.create(
      sectionId: 'chapter-1',
      sectionProgress: 0.1,
      excerpt: 'Начало',
      now: now,
    );
    final note = BookReaderNote.create(
      sectionId: 'chapter-1',
      sectionProgress: 0.1,
      excerpt: 'Начало',
      text: 'Черновик заметки',
      now: now,
    );
    final initial = BookReaderAnnotations().addBookmark(bookmark).addNote(note);
    final edited = initial.updateNote(
      note.copyWith(
        text: 'Готовая заметка',
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    );
    final empty = edited.removeBookmark(bookmark.id).removeNote(note.id);

    expect(initial.notes.single.text, 'Черновик заметки');
    expect(edited.notes.single.text, 'Готовая заметка');
    expect(empty.bookmarks, isEmpty);
    expect(empty.notes, isEmpty);
  });

  test('a new overlapping highlight replaces the old color range', () {
    final now = DateTime.utc(2026, 7, 14, 12);
    BookReaderHighlight highlight(int start, int end, String excerpt) =>
        BookReaderHighlight.create(
          sectionId: 'chapter-1',
          sectionProgress: 0.2,
          startOffset: start,
          endOffset: end,
          excerpt: excerpt,
          now: now.add(Duration(seconds: start)),
        );

    final annotations = BookReaderAnnotations()
        .addHighlight(highlight(0, 10, 'Первое'))
        .addHighlight(highlight(8, 16, 'Второе'))
        .addHighlight(highlight(20, 25, 'Третье'));

    expect(annotations.highlights, hasLength(2));
    expect(
      annotations.highlights.map((item) => item.excerpt),
      containsAll(['Второе', 'Третье']),
    );
  });
}
