import 'package:dnevnik/features/books/presentation/reader/book_reader_selection_resolver.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a local page selection to the whole chapter', () {
    final selection = BookReaderSelectionResolver.resolve(
      selection: const TextSelection(baseOffset: 1, extentOffset: 8),
      globalStart: 6,
      localLength: 10,
      plainText: 'Первая вторая третья',
    );

    expect(selection, isNotNull);
    expect(selection!.startOffset, 7);
    expect(selection.endOffset, 13);
    expect(selection.text, 'вторая');
  });

  test('trims whitespace without producing an empty selection', () {
    final selection = BookReaderSelectionResolver.resolve(
      selection: const TextSelection(baseOffset: 0, extentOffset: 5),
      globalStart: 0,
      localLength: 5,
      plainText: '  текст',
    );
    final whitespaceOnly = BookReaderSelectionResolver.resolve(
      selection: const TextSelection(baseOffset: 0, extentOffset: 2),
      globalStart: 0,
      localLength: 2,
      plainText: '  текст',
    );

    expect(selection!.text, 'тек');
    expect(selection.startOffset, 2);
    expect(whitespaceOnly, isNull);
  });
}
