import 'package:dnevnik/features/books/domain/book_section.dart';

enum TreeMoveDirection { up, down }

class SectionTreeEditor {
  const SectionTreeEditor._();

  static List<BookSection> insertAtEndOfParent(
    List<BookSection> sections,
    BookSection section,
  ) {
    if (section.parentId == null) {
      return [...sections, section];
    }
    final parentIndex = sections.indexWhere(
      (candidate) => candidate.id == section.parentId,
    );
    if (parentIndex < 0) {
      return [...sections, section.copyWith(clearParent: true)];
    }
    final familyIds = subtreeIds(sections, section.parentId!);
    var insertionIndex = parentIndex + 1;
    for (var index = parentIndex + 1; index < sections.length; index += 1) {
      if (!familyIds.contains(sections[index].id)) {
        break;
      }
      insertionIndex = index + 1;
    }
    return [
      ...sections.take(insertionIndex),
      section,
      ...sections.skip(insertionIndex),
    ];
  }

  static List<BookSection> removeSubtree(
    List<BookSection> sections,
    String sectionId,
  ) {
    final removedIds = subtreeIds(sections, sectionId);
    return sections
        .where((section) => !removedIds.contains(section.id))
        .toList();
  }

  static List<BookSection> moveSubtree(
    List<BookSection> sections,
    String sectionId,
    TreeMoveDirection direction,
  ) {
    final section = sections.where((item) => item.id == sectionId).firstOrNull;
    if (section == null) return [...sections];
    final siblings = sections
        .where((item) => item.parentId == section.parentId)
        .toList();
    final siblingIndex = siblings.indexWhere((item) => item.id == sectionId);
    final targetIndex = direction == TreeMoveDirection.up
        ? siblingIndex - 1
        : siblingIndex + 1;
    if (siblingIndex < 0 || targetIndex < 0 || targetIndex >= siblings.length) {
      return [...sections];
    }

    final movingIds = subtreeIds(sections, sectionId);
    final movingBlock = sections
        .where((item) => movingIds.contains(item.id))
        .toList();
    final remaining = sections
        .where((item) => !movingIds.contains(item.id))
        .toList();
    final target = siblings[targetIndex];
    final targetIds = subtreeIds(remaining, target.id);
    final targetPositions = <int>[
      for (var index = 0; index < remaining.length; index += 1)
        if (targetIds.contains(remaining[index].id)) index,
    ];
    if (targetPositions.isEmpty) return [...sections];
    final insertionIndex = direction == TreeMoveDirection.up
        ? targetPositions.first
        : targetPositions.last + 1;
    return [
      ...remaining.take(insertionIndex),
      ...movingBlock,
      ...remaining.skip(insertionIndex),
    ];
  }

  static bool canMoveToTarget(
    List<BookSection> sections,
    String sectionId,
    String targetId,
  ) {
    if (sectionId == targetId) return false;
    final section = sections.where((item) => item.id == sectionId).firstOrNull;
    final target = sections.where((item) => item.id == targetId).firstOrNull;
    if (section == null || target == null) return false;
    if (subtreeIds(sections, sectionId).contains(targetId)) return false;
    return switch (section.type) {
      BookSectionType.part => target.type == BookSectionType.part,
      BookSectionType.chapter =>
        target.type == BookSectionType.part ||
            target.type == BookSectionType.chapter,
      BookSectionType.scene =>
        target.type == BookSectionType.chapter ||
            target.type == BookSectionType.scene,
    };
  }

  /// Moves a complete subtree onto another visible tree item.
  ///
  /// Dropping a chapter on a part or a scene on a chapter appends it to that
  /// parent. Dropping on an item of the same type places it before that item
  /// and adopts its parent, which also supports moving between parts.
  static List<BookSection> moveToTarget(
    List<BookSection> sections,
    String sectionId,
    String targetId,
  ) {
    if (!canMoveToTarget(sections, sectionId, targetId)) return [...sections];
    final section = sections.firstWhere((item) => item.id == sectionId);
    final target = sections.firstWhere((item) => item.id == targetId);
    final movingIds = subtreeIds(sections, sectionId);
    final movingBlock = sections
        .where((item) => movingIds.contains(item.id))
        .toList();
    final remaining = sections
        .where((item) => !movingIds.contains(item.id))
        .toList();

    final droppedInside =
        (section.type == BookSectionType.chapter &&
            target.type == BookSectionType.part) ||
        (section.type == BookSectionType.scene &&
            target.type == BookSectionType.chapter);
    final newParentId = droppedInside ? target.id : target.parentId;
    movingBlock[0] = movingBlock.first.copyWith(
      parentId: newParentId,
      clearParent: newParentId == null,
      updatedAt: DateTime.now(),
    );

    final targetIndex = remaining.indexWhere((item) => item.id == target.id);
    if (targetIndex < 0) return [...sections];
    var insertionIndex = targetIndex;
    if (droppedInside) {
      final targetIds = subtreeIds(remaining, target.id);
      insertionIndex = targetIndex + 1;
      for (var index = targetIndex + 1; index < remaining.length; index += 1) {
        if (!targetIds.contains(remaining[index].id)) break;
        insertionIndex = index + 1;
      }
    }
    return [
      ...remaining.take(insertionIndex),
      ...movingBlock,
      ...remaining.skip(insertionIndex),
    ];
  }

  static Set<String> subtreeIds(List<BookSection> sections, String sectionId) {
    final result = <String>{sectionId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final section in sections) {
        if (section.parentId != null &&
            result.contains(section.parentId) &&
            result.add(section.id)) {
          changed = true;
        }
      }
    }
    return result;
  }
}
