import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter/material.dart';

class BookNavigator extends StatelessWidget {
  const BookNavigator({
    required this.controller,
    this.closeAfterSelection = false,
    super.key,
  });

  final AuthorWorkspaceController controller;
  final bool closeAfterSelection;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = controller.activeProject!;
    return Material(
      color: AppTheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(
                strings.manuscript,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(
                project.metadata.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: PopupMenuButton<BookSectionType>(
                tooltip: strings.addPage,
                onSelected: controller.addSection,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: BookSectionType.part,
                    child: Text(strings.newPart),
                  ),
                  PopupMenuItem(
                    value: BookSectionType.chapter,
                    child: Text(strings.newChapter),
                  ),
                  PopupMenuItem(
                    value: BookSectionType.scene,
                    child: Text(strings.newScene),
                  ),
                ],
                icon: const Icon(Icons.add),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: project.sections.length,
                itemBuilder: (context, index) {
                  final section = project.sections[index];
                  return _SectionTile(
                    section: section,
                    isActive: section.id == project.activeSectionId,
                    depth: _depthOf(project.sections, section),
                    onTap: () {
                      controller.selectSection(section.id);
                      if (closeAfterSelection) Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.library_books_outlined),
              title: Text(strings.library),
              trailing: IconButton(
                tooltip: strings.newBook,
                onPressed: controller.addProject,
                icon: const Icon(Icons.add_box_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _depthOf(List<BookSection> sections, BookSection section) {
    var depth = 0;
    var parentId = section.parentId;
    final visited = <String>{};
    while (parentId != null && visited.add(parentId)) {
      depth += 1;
      parentId = sections
          .where((candidate) => candidate.id == parentId)
          .firstOrNull
          ?.parentId;
    }
    return depth.clamp(0, 2);
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.isActive,
    required this.depth,
    required this.onTap,
  });

  final BookSection section;
  final bool isActive;
  final int depth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: depth * 18.0),
    child: ListTile(
      dense: true,
      selected: isActive,
      selectedTileColor: AppTheme.accent.withValues(alpha: 0.12),
      leading: Icon(switch (section.type) {
        BookSectionType.part => Icons.folder_outlined,
        BookSectionType.chapter => Icons.article_outlined,
        BookSectionType.scene => Icons.short_text,
      }, color: isActive ? AppTheme.accent : Colors.blueGrey),
      title: Text(section.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    ),
  );
}
