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

  test('honors and preserves an author-inserted page break', () {
    final source = [
      {'insert': 'Текст до разрыва\n'},
      {
        'insert': {'bookPageBreak': '1'},
      },
      {'insert': '\nТекст после разрыва\n'},
    ];

    final split = BookPagePaginator.splitAtFirstHardPageBreak(source, 100);

    expect(split, isNotNull);
    expect(split!.overflow, [
      {'insert': 'Текст после разрыва\n'},
    ]);
    expect(BookPagePaginator.merge([split.visible, split.overflow]), source);
  });

  test('does not apply a page break that is below measured content', () {
    final source = [
      {'insert': 'Длинный текст перед разрывом\n'},
      {
        'insert': {'bookPageBreak': '1'},
      },
      {'insert': '\nПродолжение\n'},
    ];

    expect(BookPagePaginator.splitAtFirstHardPageBreak(source, 5), isNull);
  });
}
