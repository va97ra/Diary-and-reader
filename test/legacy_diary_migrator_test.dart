import 'package:dnevnik/features/books/application/legacy_diary_migrator.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/diary/domain/diary_entry.dart';
import 'package:dnevnik/features/diary/domain/diary_snapshot.dart';
import 'package:dnevnik/features/diary/domain/page_margins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migrates diary entries and pages into semantic book chapters', () {
    final createdAt = DateTime.utc(2026, 7, 14);
    final snapshot = DiarySnapshot(
      entries: [
        DiaryEntry(
          id: 'entry-1',
          title: 'Первая глава',
          createdAt: createdAt,
          pages: [
            [
              {'insert': 'Первая страница\n'},
            ],
            [
              {
                'insert': 'Вторая страница',
                'attributes': {'bold': true},
              },
              {'insert': '\n'},
            ],
          ],
        ),
      ],
      activeEntryId: 'entry-1',
      languageCode: 'ru',
      margins: const PageMargins.normal(),
    );

    final workspace = LegacyDiaryMigrator.migrate(snapshot);
    final project = workspace.activeProject!;
    final chapter = project.activeSection!;

    expect(project.metadata.title, 'Моя книга');
    expect(chapter.type, BookSectionType.chapter);
    expect(chapter.content, hasLength(3));
    expect(chapter.content[1]['attributes'], {'bold': true});
  });
}
