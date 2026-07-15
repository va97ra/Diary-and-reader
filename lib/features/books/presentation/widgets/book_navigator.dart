import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/section_tree_editor.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_cover_view.dart';
import 'package:flutter/material.dart';

class BookNavigator extends StatelessWidget {
  const BookNavigator({
    required this.controller,
    this.closeAfterSelection = false,
    this.onImportBook,
    this.onOpenReader,
    super.key,
  });

  final AuthorWorkspaceController controller;
  final bool closeAfterSelection;
  final VoidCallback? onImportBook;
  final VoidCallback? onOpenReader;

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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.isReadOnly
                              ? strings.library
                              : strings.manuscript,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: project.id,
                            isExpanded: true,
                            items: controller.projects
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.id,
                                    child: Row(
                                      children: [
                                        BookCoverView(
                                          project: item,
                                          width: 28,
                                          height: 40,
                                          borderRadius: 4,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.metadata.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (item.isReadOnly)
                                                Text(
                                                  strings.importedBook,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.labelSmall,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (id) {
                              if (id == null) return;
                              controller.selectProject(id);
                              if (closeAfterSelection) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!project.isReadOnly)
                    PopupMenuButton<BookSectionType>(
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
                ],
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
                      if (project.isReadOnly && onOpenReader != null) {
                        controller.updateReaderProgress(
                          BookReaderProgress(sectionId: section.id),
                        );
                        if (closeAfterSelection) Navigator.of(context).pop();
                        onOpenReader?.call();
                        return;
                      }
                      controller.selectSection(section.id);
                      if (closeAfterSelection) Navigator.of(context).pop();
                    },
                    onAction: project.isReadOnly
                        ? null
                        : (action) =>
                              _handleSectionAction(context, section, action),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.library_books_outlined),
              title: Text(strings.library),
              trailing: PopupMenuButton<_BookAction>(
                key: const ValueKey('library-book-actions'),
                onSelected: (action) => _handleBookAction(context, action),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _BookAction.add,
                    child: Text(strings.newBook),
                  ),
                  PopupMenuItem(
                    value: _BookAction.import,
                    child: Text(strings.importEbook),
                  ),
                  PopupMenuItem(
                    value: _BookAction.delete,
                    child: Text(strings.deleteBook),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSectionAction(
    BuildContext context,
    BookSection section,
    _SectionAction action,
  ) async {
    if (action == _SectionAction.up) {
      controller.moveSection(section.id, TreeMoveDirection.up);
      return;
    }
    if (action == _SectionAction.down) {
      controller.moveSection(section.id, TreeMoveDirection.down);
      return;
    }
    final confirmed = await _confirmDelete(
      context,
      AppStrings.of(context).deleteSection,
      AppStrings.of(context).deleteSectionQuestion,
    );
    if (confirmed) controller.deleteSection(section.id);
  }

  Future<void> _handleBookAction(
    BuildContext context,
    _BookAction action,
  ) async {
    if (action == _BookAction.add) {
      controller.addProject();
      return;
    }
    if (action == _BookAction.import) {
      if (closeAfterSelection) Navigator.of(context).pop();
      onImportBook?.call();
      return;
    }
    final confirmed = await _confirmDelete(
      context,
      AppStrings.of(context).deleteBook,
      AppStrings.of(context).deleteBookQuestion,
    );
    if (confirmed) controller.deleteProject(controller.activeProject!.id);
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    String title,
    String message,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AppStrings.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(title),
            ),
          ],
        ),
      ) ??
      false;

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
    required this.onAction,
  });

  final BookSection section;
  final bool isActive;
  final int depth;
  final VoidCallback onTap;
  final ValueChanged<_SectionAction>? onAction;

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
      trailing: onAction == null
          ? null
          : PopupMenuButton<_SectionAction>(
              onSelected: onAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _SectionAction.up,
                  child: Text(AppStrings.of(context).moveUp),
                ),
                PopupMenuItem(
                  value: _SectionAction.down,
                  child: Text(AppStrings.of(context).moveDown),
                ),
                PopupMenuItem(
                  value: _SectionAction.delete,
                  child: Text(AppStrings.of(context).deleteSection),
                ),
              ],
            ),
      onTap: onTap,
    ),
  );
}

enum _SectionAction { up, down, delete }

enum _BookAction { add, import, delete }
