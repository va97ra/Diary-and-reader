import 'package:dnevnik/features/books/application/book_library_query.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('library query searches filters collections and sorts books', () {
    final now = DateTime.utc(2026, 7, 16);
    final draft =
        BookProject.create(
          title: 'Северный ветер',
          chapterTitle: 'Глава 1',
          now: now,
        ).copyWith(
          metadata: const BookMetadata(
            title: 'Северный ветер',
            author: 'Анна Автор',
          ),
          collectionName: 'Романы',
        );
    final imported = BookProject(
      id: 'imported-1',
      metadata: const BookMetadata(
        title: 'Другой мир',
        author: 'Борис Писатель',
      ),
      sections: draft.sections,
      activeSectionId: draft.sections.single.id,
      createdAt: now,
      updatedAt: now.add(const Duration(days: 1)),
      kind: BookProjectKind.importedBook,
      collectionName: 'Фантастика',
      readerProgress: BookReaderProgress(
        sectionId: draft.sections.single.id,
        sectionProgress: 1,
      ),
    );

    expect(const BookLibraryQuery(search: 'анна').apply([draft, imported]), [
      draft,
    ]);
    expect(
      const BookLibraryQuery(
        filter: BookLibraryFilter.imported,
      ).apply([draft, imported]),
      [imported],
    );
    expect(
      const BookLibraryQuery(collectionName: 'Романы').apply([draft, imported]),
      [draft],
    );
    expect(
      const BookLibraryQuery(
        sort: BookLibrarySort.progress,
      ).apply([draft, imported]),
      [imported, draft],
    );
  });
}
