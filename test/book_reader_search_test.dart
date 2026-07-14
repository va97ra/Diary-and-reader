import 'package:dnevnik/features/books/application/book_reader_search.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search finds all case-insensitive matches across book sections', () {
    final now = DateTime.utc(2026, 7, 14);
    final sections = [
      BookSection.create(
        id: 'chapter-1',
        title: 'Первая глава',
        type: BookSectionType.chapter,
        now: now,
      ).copyWith(
        content: [
          {'insert': 'Первый дракон улетел. Второй ДРАКОН остался.\n'},
        ],
      ),
      BookSection.create(
        id: 'chapter-2',
        title: 'Вторая глава',
        type: BookSectionType.chapter,
        now: now,
      ).copyWith(
        content: [
          {'insert': 'Здесь дракон вернулся домой.\n'},
        ],
      ),
    ];

    final results = BookReaderSearch.find(sections, 'дракон');

    expect(results, hasLength(3));
    expect(results.first.sectionId, 'chapter-1');
    expect(results.last.sectionId, 'chapter-2');
    expect(results.first.excerpt, contains('Первый дракон'));
    expect(results[1].sectionProgress, greaterThan(results[0].sectionProgress));
  });

  test('search ignores short queries and respects the result limit', () {
    final section =
        BookSection.create(
          id: 'chapter-1',
          title: 'Глава',
          type: BookSectionType.chapter,
        ).copyWith(
          content: [
            {'insert': 'да да да да\n'},
          ],
        );

    expect(BookReaderSearch.find([section], 'д'), isEmpty);
    expect(BookReaderSearch.find([section], 'да', limit: 2), hasLength(2));
  });

  test('search includes matching section titles', () {
    final section = BookSection.create(
      id: 'chapter-1',
      title: 'Возвращение домой',
      type: BookSectionType.chapter,
    );

    final result = BookReaderSearch.find([section], 'возвращение').single;

    expect(result.sectionId, 'chapter-1');
    expect(result.sectionProgress, 0);
    expect(result.excerpt, 'Возвращение домой');
  });
}
