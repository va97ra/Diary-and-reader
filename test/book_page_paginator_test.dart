import 'package:dnevnik/features/books/application/book_page_paginator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visual page split does not add a paragraph break when merged', () {
    final source = [
      {
        'insert': 'Очень длинный абзац для двух страниц',
        'attributes': {'italic': true},
      },
      {'insert': '\n'},
    ];

    final split = BookPagePaginator.split(source, 18);
    final merged = BookPagePaginator.merge([split.visible, split.overflow]);

    expect(merged, source);
  });

  test('keeps real paragraph ending at a page boundary', () {
    final source = [
      {'insert': 'Первый абзац\nВторой абзац\n'},
    ];

    final split = BookPagePaginator.split(source, 13);
    final merged = BookPagePaginator.merge([split.visible, split.overflow]);

    expect(merged, source);
  });
}
