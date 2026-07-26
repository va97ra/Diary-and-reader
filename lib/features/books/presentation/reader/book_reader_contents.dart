import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter/material.dart';

class BookReaderContents extends StatelessWidget {
  const BookReaderContents({
    required this.sections,
    required this.activeSectionId,
    required this.onSelected,
    super.key,
  });

  final List<BookSection> sections;
  final String activeSectionId;
  final ValueChanged<BookSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final titleCounts = <String, int>{};
    for (final section in sections) {
      final key = section.title.trim().toLowerCase();
      titleCounts[key] = (titleCounts[key] ?? 0) + 1;
    }
    return ListView.builder(
      key: const ValueKey('reader-contents'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        final depth = _depthOf(section);
        final duplicateTitle =
            titleCounts[section.title.trim().toLowerCase()]! > 1;
        return ListTile(
          selected: section.id == activeSectionId,
          leading: Icon(_iconFor(section.type), size: 20),
          contentPadding: EdgeInsets.only(left: 16 + depth * 18, right: 12),
          title: Text(
            duplicateTitle ? strings.sectionTitle(index + 1) : section.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: duplicateTitle
              ? Text(
                  section.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          onTap: () => onSelected(section),
        );
      },
    );
  }

  int _depthOf(BookSection section) {
    var depth = 0;
    var parentId = section.parentId;
    while (parentId != null && depth < 3) {
      final parent = sections.where((item) => item.id == parentId).firstOrNull;
      if (parent == null) break;
      depth++;
      parentId = parent.parentId;
    }
    return depth;
  }

  IconData _iconFor(BookSectionType type) => switch (type) {
    BookSectionType.part => Icons.menu_book_outlined,
    BookSectionType.chapter => Icons.article_outlined,
    BookSectionType.scene => Icons.notes_outlined,
  };
}
