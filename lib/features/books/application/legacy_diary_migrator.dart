import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/legacy/legacy_diary_snapshot.dart';

class LegacyDiaryMigrator {
  const LegacyDiaryMigrator._();

  static AuthorWorkspaceSnapshot migrate(LegacyDiarySnapshot snapshot) {
    final now = DateTime.now();
    final sections = snapshot.entries
        .map(
          (entry) => BookSection(
            id: entry.id,
            title: entry.title,
            type: BookSectionType.chapter,
            status: DraftStatus.draft,
            content: mergeRichDocuments(entry.pages),
            createdAt: entry.createdAt,
            updatedAt: entry.createdAt,
          ),
        )
        .toList();
    if (sections.isEmpty) {
      sections.add(
        BookSection.create(
          id: 'legacy-chapter-1',
          title: snapshot.languageCode == 'en' ? 'Chapter 1' : 'Глава 1',
          type: BookSectionType.chapter,
          now: now,
        ),
      );
    }

    final createdAt = sections
        .map((section) => section.createdAt)
        .reduce((first, next) => first.isBefore(next) ? first : next);
    final updatedAt = sections
        .map((section) => section.updatedAt)
        .reduce((first, next) => first.isAfter(next) ? first : next);
    final activeId =
        sections.any((section) => section.id == snapshot.activeEntryId)
        ? snapshot.activeEntryId
        : sections.first.id;
    final project = BookProject(
      id: 'migrated-diary',
      metadata: BookMetadata(
        title: snapshot.languageCode == 'en' ? 'My book' : 'Моя книга',
        languageCode: snapshot.languageCode,
      ),
      sections: sections,
      activeSectionId: activeId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    return AuthorWorkspaceSnapshot(
      projects: [project],
      activeProjectId: project.id,
      languageCode: snapshot.languageCode,
    );
  }
}
