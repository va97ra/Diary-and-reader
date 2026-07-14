import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('book project round-trips metadata and section hierarchy', () {
    final now = DateTime.utc(2026, 7, 14);
    final project = BookProject.create(
      title: 'Тестовая книга',
      chapterTitle: 'Глава 1',
      now: now,
    );
    final chapter = project.sections.single;
    final scene = BookSection.create(
      id: 'scene-1',
      title: 'Сцена 1',
      type: BookSectionType.scene,
      parentId: chapter.id,
      now: now,
    ).copyWith(targetWords: 1200);
    final withScene = project.copyWith(
      sections: [...project.sections, scene],
      activeSectionId: scene.id,
    );

    final restored = BookProject.fromJson(withScene.toJson());

    expect(restored.metadata.title, 'Тестовая книга');
    expect(restored.activeSection?.id, scene.id);
    expect(restored.childrenOf(chapter.id).single.title, 'Сцена 1');
    expect(restored.activeSection?.targetWords, 1200);
  });

  test('invalid active section falls back to the first section', () {
    final project = BookProject.fromJson({
      'id': 'book-1',
      'metadata': {'title': 'Книга'},
      'activeSectionId': 'missing',
      'sections': [
        {
          'id': 'chapter-1',
          'title': 'Глава 1',
          'type': 'chapter',
          'status': 'draft',
          'content': [
            {'insert': '\n'},
          ],
        },
      ],
    });

    expect(project.activeSectionId, 'chapter-1');
  });
}
