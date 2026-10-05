import 'package:dnevnik/features/books/application/book_reader_text_anchor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps a valid range and relocates a shifted excerpt', () {
    const original = 'Начало. Важный фрагмент. Конец.';
    final valid = BookReaderTextAnchor.resolve(
      text: original,
      startOffset: 8,
      endOffset: 23,
      excerpt: 'Важный фрагмент',
      sectionProgress: 0.25,
    )!;
    const edited = 'Новое вступление. Начало. Важный фрагмент. Конец.';
    final shifted = BookReaderTextAnchor.resolve(
      text: edited,
      startOffset: 8,
      endOffset: 23,
      excerpt: 'Важный фрагмент',
      sectionProgress: 0.5,
    )!;

    expect(original.substring(valid.start, valid.end), 'Важный фрагмент');
    expect(edited.substring(shifted.start, shifted.end), 'Важный фрагмент');
    expect(shifted.start, greaterThan(valid.start));
  });

  test('chooses the occurrence closest to saved progress', () {
    const text = 'Повтор. Другая часть. Повтор.';
    final range = BookReaderTextAnchor.resolve(
      text: text,
      startOffset: 0,
      endOffset: 1,
      excerpt: 'Повтор',
      sectionProgress: 0.9,
    )!;

    expect(range.start, text.lastIndexOf('Повтор'));
  });

  test('marks nothing once the author has rewritten the words', () {
    // The highlight was on "chapter" at 5..12; those offsets now fall in
    // the middle of other words.
    final range = BookReaderTextAnchor.resolve(
      text: 'вечером на лавочке парочка сидит',
      startOffset: 5,
      endOffset: 12,
      excerpt: 'chapter',
      sectionProgress: 0.1,
    );

    expect(range, isNull);
  });
}
