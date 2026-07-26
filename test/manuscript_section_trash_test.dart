import 'package:dnevnik/features/books/application/manuscript_project_editor.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deleted chapter subtree can be restored at its original position', () {
    var project = BookProject.create(
      title: 'Книга',
      chapterTitle: 'Глава 1',
      now: DateTime.utc(2026, 7, 22),
    );
    final firstChapterId = project.activeSectionId!;
    project = ManuscriptProjectEditor.addSection(
      project,
      BookSectionType.scene,
      languageCode: 'ru',
    );
    final sceneId = project.activeSectionId!;
    project = ManuscriptProjectEditor.addSection(
      project,
      BookSectionType.chapter,
      languageCode: 'ru',
    );
    expect(project.sections.last.parentId, isNull);
    expect(project.sections.map((section) => section.id).toSet(), hasLength(3));

    final deleted = ManuscriptProjectEditor.deleteSection(
      project,
      firstChapterId,
      languageCode: 'ru',
    );
    expect(
      deleted.sections.map((section) => section.id),
      isNot(contains(sceneId)),
    );
    expect(deleted.sectionTrash.single.sections, hasLength(2));

    final restored = ManuscriptProjectEditor.restoreDeletedSection(
      deleted,
      deleted.sectionTrash.single.id,
    );
    expect(restored.sections.first.id, firstChapterId);
    expect(restored.sections[1].id, sceneId);
    expect(restored.sectionTrash, isEmpty);
  });

  test('trash survives project serialization and can be emptied', () {
    var project = BookProject.create(title: 'Книга', chapterTitle: 'Глава 1');
    project = ManuscriptProjectEditor.addSection(
      project,
      BookSectionType.chapter,
      languageCode: 'ru',
    );
    project = ManuscriptProjectEditor.deleteSection(
      project,
      project.sections.first.id,
      languageCode: 'ru',
    );

    final decoded = BookProject.fromJson(project.toJson());
    expect(decoded.sectionTrash, hasLength(1));
    expect(
      ManuscriptProjectEditor.emptySectionTrash(decoded).sectionTrash,
      isEmpty,
    );
  });
}
