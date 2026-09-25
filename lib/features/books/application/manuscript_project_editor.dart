import 'package:dnevnik/features/books/application/book_deleted_text.dart';
import 'package:dnevnik/features/books/application/book_manuscript_search.dart';
import 'package:dnevnik/features/books/application/section_tree_editor.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_default_titles.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/book_section_trash.dart';
import 'package:dnevnik/features/books/domain/book_text_trash.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/domain/unique_timestamp.dart';

abstract final class ManuscriptProjectEditor {
  static BookProject addSection(
    BookProject project,
    BookSectionType type, {
    required String languageCode,
  }) {
    final section = BookSection.create(
      title: BookDefaultTitles.section(type, languageCode),
      type: type,
      parentId: _parentForNewSection(project, type),
    );
    return project.copyWith(
      sections: SectionTreeEditor.insertAtEndOfParent(
        project.sections,
        section,
      ),
      activeSectionId: section.id,
      updatedAt: DateTime.now(),
    );
  }

  static BookProject moveSection(
    BookProject project,
    String id,
    TreeMoveDirection direction,
  ) => project.copyWith(
    sections: SectionTreeEditor.moveSubtree(project.sections, id, direction),
    updatedAt: DateTime.now(),
  );

  static BookProject deleteSection(
    BookProject project,
    String id, {
    required String languageCode,
  }) {
    final originalIndex = project.sections.indexWhere(
      (section) => section.id == id,
    );
    if (originalIndex < 0) return project;
    final removedIds = SectionTreeEditor.subtreeIds(project.sections, id);
    final removed = project.sections
        .where((section) => removedIds.contains(section.id))
        .toList();
    var sections = SectionTreeEditor.removeSubtree(project.sections, id);
    if (sections.isEmpty) {
      sections = [
        BookSection.create(
          title: BookDefaultTitles.firstChapter(languageCode),
          type: BookSectionType.chapter,
        ),
      ];
    }
    final activeStillExists = sections.any(
      (section) => section.id == project.activeSectionId,
    );
    final sectionIds = sections.map((section) => section.id).toSet();
    return project.copyWith(
      sections: sections,
      sectionTrash: [
        ...project.sectionTrash,
        BookSectionTrashEntry(
          id: 'trash-${DateTime.now().microsecondsSinceEpoch}',
          deletedAt: DateTime.now(),
          originalIndex: originalIndex,
          sections: removed,
        ),
      ].takeLast(30).toList(),
      activeSectionId: activeStillExists
          ? project.activeSectionId
          : sections.first.id,
      readerProgress: sectionIds.contains(project.readerProgress.sectionId)
          ? project.readerProgress
          : BookReaderProgress(sectionId: sections.first.id),
      readerAnnotations: project.readerAnnotations.retainSections(sectionIds),
      updatedAt: DateTime.now(),
    );
  }

  static BookProject restoreDeletedSection(
    BookProject project,
    String trashId,
  ) {
    final entry = project.sectionTrash
        .where((candidate) => candidate.id == trashId)
        .firstOrNull;
    if (entry == null || entry.sections.isEmpty) return project;
    final activeIds = project.sections.map((section) => section.id).toSet();
    if (entry.sections.any((section) => activeIds.contains(section.id))) {
      return project;
    }
    final insertion = entry.originalIndex.clamp(0, project.sections.length);
    return project.copyWith(
      sections: [
        ...project.sections.take(insertion),
        ...entry.sections,
        ...project.sections.skip(insertion),
      ],
      activeSectionId: entry.root.id,
      sectionTrash: project.sectionTrash
          .where((candidate) => candidate.id != trashId)
          .toList(),
      updatedAt: DateTime.now(),
    );
  }

  static BookProject deleteTrashEntry(BookProject project, String trashId) =>
      project.copyWith(
        sectionTrash: project.sectionTrash
            .where((entry) => entry.id != trashId)
            .toList(),
        updatedAt: DateTime.now(),
      );

  static BookProject emptyTrash(BookProject project) => project.copyWith(
    sectionTrash: const [],
    textTrash: const [],
    updatedAt: DateTime.now(),
  );

  /// Puts deleted text back where it was, in its chapter if that still
  /// exists and in the active one otherwise, and opens that chapter.
  static BookProject restoreDeletedText(BookProject project, String trashId) {
    final entry = project.textTrash
        .where((candidate) => candidate.id == trashId)
        .firstOrNull;
    if (entry == null) return project;
    final target =
        project.sections
            .where((section) => section.id == entry.sectionId)
            .firstOrNull ??
        project.activeSection;
    if (target == null) return project;
    final now = DateTime.now();
    final content = BookDeletedText.restore(
      target.content,
      entry.offset,
      entry.content,
    );
    return project.copyWith(
      sections: [
        for (final section in project.sections)
          section.id == target.id
              ? section.copyWith(content: content, updatedAt: now)
              : section,
      ],
      activeSectionId: target.id,
      textTrash: project.textTrash.where((item) => item != entry).toList(),
      updatedAt: now,
    );
  }

  static BookProject deleteTextTrashEntry(
    BookProject project,
    String trashId,
  ) => project.copyWith(
    textTrash: project.textTrash.where((entry) => entry.id != trashId).toList(),
    updatedAt: DateTime.now(),
  );

  static BookProject updateSectionTitle(BookProject project, String title) =>
      _updateActiveSection(
        project,
        (section) => section.copyWith(title: title),
      );

  /// Deleted fragments kept in the trash; older ones make room for new.
  static const textTrashLimit = 50;

  /// Replaces the active chapter's text. A deleted word or more, or a
  /// deleted picture, goes to the trash so it can be put back.
  static BookProject updateSectionContent(
    BookProject project,
    RichDocument content,
  ) {
    final section = project.activeSection;
    final now = DateTime.now();
    final updated = _updateActiveSection(
      project,
      (section) => section.copyWith(content: content, updatedAt: now),
    );
    final deleted = section == null
        ? null
        : BookDeletedText.between(section.content, content);
    if (section == null || deleted == null) return updated;
    return updated.copyWith(
      textTrash: [
        ...project.textTrash,
        BookTextTrashEntry(
          id: 'text-trash-${uniqueTimestamp(now)}',
          deletedAt: now,
          sectionId: section.id,
          offset: deleted.offset,
          content: deleted.content,
        ),
      ].takeLast(textTrashLimit).toList(),
    );
  }

  static BookProject addAsset(BookProject project, BookAsset asset) =>
      project.copyWith(
        assets: [
          ...project.assets.where((existing) => existing.id != asset.id),
          asset,
        ],
        updatedAt: DateTime.now(),
      );

  static ManuscriptReplaceResult replaceAll(
    BookProject project,
    String query,
    String replacement, {
    required bool caseSensitive,
  }) {
    var count = 0;
    final sections = project.sections.map((section) {
      final result = BookManuscriptSearch.replaceAll(
        section.content,
        query,
        replacement,
        caseSensitive: caseSensitive,
      );
      count += result.count;
      return result.count == 0
          ? section
          : section.copyWith(
              content: result.document,
              updatedAt: DateTime.now(),
            );
    }).toList();
    return ManuscriptReplaceResult(
      project: count == 0
          ? project
          : project.copyWith(sections: sections, updatedAt: DateTime.now()),
      count: count,
    );
  }

  static BookProject updateSectionStatus(
    BookProject project,
    DraftStatus status,
  ) => _updateActiveSection(
    project,
    (section) => section.copyWith(status: status, updatedAt: DateTime.now()),
  );

  static BookProject updateSectionTargetWords(
    BookProject project,
    int targetWords,
  ) => _updateActiveSection(
    project,
    (section) =>
        section.copyWith(targetWords: targetWords, updatedAt: DateTime.now()),
  );

  static BookProject updateMetadata(
    BookProject project,
    BookMetadata metadata,
  ) => project.copyWith(metadata: metadata, updatedAt: DateTime.now());

  static BookProject updateLayoutSettings(
    BookProject project,
    BookLayoutSettings settings,
  ) => project.copyWith(layoutSettings: settings, updatedAt: DateTime.now());

  static BookProject updateParagraphSettings(
    BookProject project,
    BookParagraphSettings settings,
  ) => project.copyWith(paragraphSettings: settings, updatedAt: DateTime.now());

  static BookProject _updateActiveSection(
    BookProject project,
    BookSection Function(BookSection section) update,
  ) {
    final activeId = project.activeSectionId;
    if (activeId == null) return project;
    return project.copyWith(
      sections: project.sections
          .map((section) => section.id == activeId ? update(section) : section)
          .toList(),
      updatedAt: DateTime.now(),
    );
  }

  static String? _parentForNewSection(
    BookProject project,
    BookSectionType type,
  ) {
    final active = project.activeSection;
    if (active == null || type == BookSectionType.part) return null;
    if (type == BookSectionType.chapter) {
      if (active.type == BookSectionType.part) return active.id;
      if (active.type == BookSectionType.chapter) return active.parentId;
      final parentChapter = project.sections
          .where((section) => section.id == active.parentId)
          .firstOrNull;
      return parentChapter?.parentId;
    }
    if (active.type == BookSectionType.chapter) return active.id;
    return active.type == BookSectionType.scene ? active.parentId : null;
  }
}

class ManuscriptReplaceResult {
  const ManuscriptReplaceResult({required this.project, required this.count});

  final BookProject project;
  final int count;
}

extension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    final items = toList();
    return items.skip((items.length - count).clamp(0, items.length));
  }
}
