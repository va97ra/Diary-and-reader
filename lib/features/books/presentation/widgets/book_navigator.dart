import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/section_tree_editor.dart';
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
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.structure,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          project.metadata.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    key: const ValueKey('navigator-new-chapter'),
                    onPressed: () {
                      controller.addSection(BookSectionType.chapter);
                      if (closeAfterSelection) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(strings.newChapter),
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<BookSectionType>(
                    tooltip: strings.more,
                    onSelected: controller.addSection,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: BookSectionType.part,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(strings.newPart),
                        ),
                      ),
                      PopupMenuItem(
                        value: BookSectionType.scene,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.short_text),
                          title: Text(strings.newScene),
                        ),
                      ),
                    ],
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      child: Center(child: Text(strings.more)),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('navigator-close'),
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.close),
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
                      controller.selectSection(section.id);
                      if (closeAfterSelection) Navigator.of(context).pop();
                    },
                    onAction: (action) =>
                        _handleSectionAction(context, section, action),
                    canAcceptDrop: (movingId) =>
                        SectionTreeEditor.canMoveToTarget(
                          project.sections,
                          movingId,
                          section.id,
                        ),
                    onAcceptDrop: (movingId) =>
                        controller.moveSectionToTarget(movingId, section.id),
                  );
                },
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
    final strings = AppStrings.of(context);
    if (action == _SectionAction.up) {
      controller.moveSection(section.id, TreeMoveDirection.up);
      return;
    }
    if (action == _SectionAction.down) {
      controller.moveSection(section.id, TreeMoveDirection.down);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.of(context).deleteSection),
        content: Text(AppStrings.of(context).deleteSectionQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppStrings.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppStrings.of(context).deleteSection),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await controller.deleteSectionSafely(
        section.id,
        safetyLabel: strings.automaticBeforeDelete,
      );
    }
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
    required this.onAction,
    required this.canAcceptDrop,
    required this.onAcceptDrop,
  });

  final BookSection section;
  final bool isActive;
  final int depth;
  final VoidCallback onTap;
  final ValueChanged<_SectionAction> onAction;
  final bool Function(String movingId) canAcceptDrop;
  final ValueChanged<String> onAcceptDrop;

  @override
  Widget build(BuildContext context) => DragTarget<String>(
    onWillAcceptWithDetails: (details) => canAcceptDrop(details.data),
    onAcceptWithDetails: (details) => onAcceptDrop(details.data),
    builder: (context, candidates, rejected) {
      final accepting = candidates.whereType<String>().any(canAcceptDrop);
      return LongPressDraggable<String>(
        data: section.id,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: ListTile(
              leading: Icon(_sectionIcon(section.type)),
              title: Text(section.title, maxLines: 1),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: _tile(context, false)),
        child: _tile(context, accepting),
      );
    },
  );

  Widget _tile(BuildContext context, bool accepting) => Padding(
    padding: EdgeInsets.only(left: depth * 18.0),
    child: ListTile(
      key: ValueKey('structure-section-${section.id}'),
      selected: isActive,
      tileColor: accepting
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      selectedTileColor: accepting
          ? Theme.of(context).colorScheme.primaryContainer
          : AppTheme.accent.withValues(alpha: 0.12),
      leading: Icon(
        _sectionIcon(section.type),
        color: isActive ? AppTheme.accent : Colors.blueGrey,
      ),
      title: Text(section.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: AppStrings.of(context).dragSectionHint,
            child: const Icon(Icons.drag_indicator, color: Colors.blueGrey),
          ),
          PopupMenuButton<_SectionAction>(
            tooltip: AppStrings.of(context).more,
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
        ],
      ),
      onTap: onTap,
    ),
  );
}

IconData _sectionIcon(BookSectionType type) => switch (type) {
  BookSectionType.part => Icons.folder_outlined,
  BookSectionType.chapter => Icons.article_outlined,
  BookSectionType.scene => Icons.short_text,
};

enum _SectionAction { up, down, delete }
