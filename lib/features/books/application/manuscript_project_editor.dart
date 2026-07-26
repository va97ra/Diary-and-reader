import 'package:dnevnik/features/books/application/book_manuscript_search.dart';
import 'package:dnevnik/features/books/application/section_tree_editor.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/book_section_trash.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';

abstract final class ManuscriptProjectEditor {
  static BookProject addSection(
    BookProject project,
    BookSectionType type, {
    required String languageCode,
  }) {
    final section = BookSection.create(
      title: _defaultSectionTitle(type, languageCode),
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
          title: languageCode == 'en' ? 'Chapter 1' : 'Глава 1',
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

  static BookProject emptySectionTrash(BookProject project) =>
      project.copyWith(sectionTrash: const [], updatedAt: DateTime.now());

  static BookProject updateSectionTitle(BookProject project, String title) =>
      _updateActiveSection(
        project,
        (section) => section.copyWith(title: title),
      );

  static BookProject updateSectionContent(
    BookProject project,
    RichDocument content,
  ) => _updateActiveSection(
    project,
    (section) => section.copyWith(content: content, updatedAt: DateTime.now()),
  );

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

  static String _defaultSectionTitle(
    BookSectionType type,
    String languageCode,
  ) => switch (type) {
    BookSectionType.part => languageCode == 'en' ? 'New part' : 'Новая часть',
    BookSectionType.chapter =>
      languageCode == 'en' ? 'New chapter' : 'Новая глава',
    BookSectionType.scene => languageCode == 'en' ? 'New scene' : 'Новая сцена',
  };

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
