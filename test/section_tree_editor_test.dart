import 'package:dnevnik/features/books/application/section_tree_editor.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 7, 14);

  BookSection section(String id, BookSectionType type, {String? parentId}) =>
      BookSection.create(
        id: id,
        title: id,
        type: type,
        parentId: parentId,
        now: now,
      );

  test('moves a chapter together with its scenes', () {
    final sections = [
      section('chapter-1', BookSectionType.chapter),
      section('scene-1', BookSectionType.scene, parentId: 'chapter-1'),
      section('chapter-2', BookSectionType.chapter),
      section('scene-2', BookSectionType.scene, parentId: 'chapter-2'),
    ];

    final moved = SectionTreeEditor.moveSubtree(
      sections,
      'chapter-2',
      TreeMoveDirection.up,
    );

    expect(moved.map((item) => item.id), [
      'chapter-2',
      'scene-2',
      'chapter-1',
      'scene-1',
    ]);
  });

  test('removes a part and every nested section', () {
    final sections = [
      section('part-1', BookSectionType.part),
      section('chapter-1', BookSectionType.chapter, parentId: 'part-1'),
      section('scene-1', BookSectionType.scene, parentId: 'chapter-1'),
      section('chapter-2', BookSectionType.chapter),
    ];

    final remaining = SectionTreeEditor.removeSubtree(sections, 'part-1');

    expect(remaining.map((item) => item.id), ['chapter-2']);
  });

  test('inserts a child before the next root section', () {
    final sections = [
      section('part-1', BookSectionType.part),
      section('chapter-1', BookSectionType.chapter, parentId: 'part-1'),
      section('part-2', BookSectionType.part),
    ];
    final inserted = SectionTreeEditor.insertAtEndOfParent(
      sections,
      section('chapter-2', BookSectionType.chapter, parentId: 'part-1'),
    );

    expect(inserted.map((item) => item.id), [
      'part-1',
      'chapter-1',
      'chapter-2',
      'part-2',
    ]);
  });

  test('drops a chapter into another part together with its scenes', () {
    final sections = [
      section('part-1', BookSectionType.part),
      section('chapter-1', BookSectionType.chapter, parentId: 'part-1'),
      section('scene-1', BookSectionType.scene, parentId: 'chapter-1'),
      section('part-2', BookSectionType.part),
      section('chapter-2', BookSectionType.chapter, parentId: 'part-2'),
    ];

    final moved = SectionTreeEditor.moveToTarget(
      sections,
      'chapter-1',
      'part-2',
    );

    expect(moved.map((item) => item.id), [
      'part-1',
      'part-2',
      'chapter-2',
      'chapter-1',
      'scene-1',
    ]);
    expect(
      moved.firstWhere((item) => item.id == 'chapter-1').parentId,
      'part-2',
    );
  });

  test('drops a scene into another chapter and rejects cyclic drops', () {
    final sections = [
      section('chapter-1', BookSectionType.chapter),
      section('scene-1', BookSectionType.scene, parentId: 'chapter-1'),
      section('chapter-2', BookSectionType.chapter),
    ];

    final moved = SectionTreeEditor.moveToTarget(
      sections,
      'scene-1',
      'chapter-2',
    );
    expect(moved.last.parentId, 'chapter-2');
    expect(
      SectionTreeEditor.canMoveToTarget(sections, 'chapter-1', 'scene-1'),
      isFalse,
    );
  });

  test('generates unique ids for sections created in the same clock tick', () {
    final created = [
      for (var index = 0; index < 100; index += 1)
        BookSection.create(
          title: 'Раздел $index',
          type: BookSectionType.chapter,
          now: now,
        ),
    ];

    expect(created.map((section) => section.id).toSet(), hasLength(100));
  });
}
