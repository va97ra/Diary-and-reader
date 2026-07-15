import 'package:dnevnik/features/books/domain/book_section.dart';

class BookSectionOutlineEntry {
  const BookSectionOutlineEntry({
    required this.section,
    required this.index,
    required this.depth,
  });

  final BookSection section;
  final int index;
  final int depth;
}

abstract final class BookSectionOutline {
  static List<BookSectionOutlineEntry> flatten(List<BookSection> sections) {
    final ids = sections.map((section) => section.id).toSet();
    final byParent = <String?, List<int>>{};
    for (var index = 0; index < sections.length; index++) {
      final requestedParent = sections[index].parentId;
      final parent = requestedParent != null && ids.contains(requestedParent)
          ? requestedParent
          : null;
      byParent.putIfAbsent(parent, () => []).add(index);
    }
    final output = <BookSectionOutlineEntry>[];
    final visited = <int>{};

    void visit(int index, int depth) {
      if (!visited.add(index)) return;
      output.add(
        BookSectionOutlineEntry(
          section: sections[index],
          index: index,
          depth: depth,
        ),
      );
      for (final child in byParent[sections[index].id] ?? const <int>[]) {
        visit(child, depth + 1);
      }
    }

    for (final root in byParent[null] ?? const <int>[]) {
      visit(root, 0);
    }
    for (var index = 0; index < sections.length; index++) {
      if (!visited.contains(index)) visit(index, 0);
    }
    return output;
  }
}
