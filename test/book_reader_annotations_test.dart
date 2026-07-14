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
    final annotations = BookReaderAnnotations(
      bookmarks: [bookmark],
      notes: [note],
    );

    final restored = BookReaderAnnotations.fromJson(annotations.toJson());

    expect(restored.bookmarks.single.sectionProgress, 1);
    expect(restored.bookmarks.single.excerpt, 'Фрагмент книги');
    expect(restored.notes.single.text, 'Проверить эту сцену');
    expect(restored.notes.single.sectionProgress, 0.35);
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
}
