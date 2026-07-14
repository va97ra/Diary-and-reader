import 'package:dnevnik/features/diary/application/page_paginator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splits text operations without losing inline attributes', () {
    final split = PagePaginator.split([
      {
        'insert': 'Hello world',
        'attributes': {'bold': true},
      },
      {'insert': '\n'},
    ], 6);

    expect(split.visible.first['insert'], 'Hello ');
    expect(split.visible.first['attributes'], {'bold': true});
    expect(split.visible.last['insert'], '\n');
    expect(split.overflow.first['insert'], 'world');
    expect(split.overflow.first['attributes'], {'bold': true});
  });

  test('copies paragraph attributes to an inserted page-ending newline', () {
    final split = PagePaginator.split([
      {'insert': 'A long heading'},
      {
        'insert': '\n',
        'attributes': {'header': 1},
      },
    ], 6);

    expect(split.visible.last['attributes'], {'header': 1});
    expect(split.overflow.last['attributes'], {'header': 1});
  });

  test('replaces an empty next page instead of adding a blank paragraph', () {
    final merged = PagePaginator.prependOverflow(
      [
        {'insert': 'overflow\n'},
      ],
      [
        {'insert': '\n'},
      ],
    );

    expect(merged, [
      {'insert': 'overflow\n'},
    ]);
  });
}
