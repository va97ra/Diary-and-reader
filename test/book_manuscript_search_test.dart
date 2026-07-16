import 'package:dnevnik/features/books/application/book_manuscript_search.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finds case-insensitive matches across every manuscript section', () {
    final project = _project([
      _section('one', 'Первая глава', [
        {'insert': 'Дом стоял у реки.\n'},
      ]),
      _section('two', 'Вторая глава', [
        {'insert': 'Вернувшись в ДОМ, герой уснул.\n'},
      ]),
    ]);

    final matches = BookManuscriptSearch.find(project, 'дом');

    expect(matches, hasLength(2));
    expect(matches.map((match) => match.sectionId), ['one', 'two']);
    expect(matches.first.excerpt, contains('Дом стоял'));
  });

  test('replaces all matches without losing unrelated rich formatting', () {
    final source = <Map<String, dynamic>>[
      {
        'insert': 'Старый дом',
        'attributes': {'bold': true},
      },
      {'insert': ' и ещё один ДОМ.\n'},
    ];

    final result = BookManuscriptSearch.replaceAll(source, 'дом', 'сад');

    expect(result.count, 2);
    expect(
      richDocumentPlainText(result.document),
      'Старый сад и ещё один сад.\n',
    );
    expect(
      result.document.any(
        (operation) =>
            operation['attributes'] is Map &&
            (operation['attributes'] as Map)['bold'] == true,
      ),
      isTrue,
    );
  });
}

BookProject _project(List<BookSection> sections) {
  final now = DateTime(2026);
  return BookProject(
    id: 'book',
    metadata: const BookMetadata(title: 'Книга'),
    sections: sections,
    activeSectionId: sections.first.id,
    createdAt: now,
    updatedAt: now,
  );
}

BookSection _section(String id, String title, RichDocument content) {
  final now = DateTime(2026);
  return BookSection(
    id: id,
    title: title,
    type: BookSectionType.chapter,
    status: DraftStatus.draft,
    content: content,
    createdAt: now,
    updatedAt: now,
  );
}
