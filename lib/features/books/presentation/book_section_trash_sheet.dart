import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_section_trash.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:flutter/material.dart';

enum _TrashAction { restore, delete }

class BookSectionTrashSheet extends StatefulWidget {
  const BookSectionTrashSheet({required this.controller, super.key});

  final AuthorWorkspaceController controller;

  @override
  State<BookSectionTrashSheet> createState() => _BookSectionTrashSheetState();
}

class _BookSectionTrashSheetState extends State<BookSectionTrashSheet> {
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final entries = widget.controller.activeProject?.sectionTrash ?? const [];
    return SafeArea(
      child: Column(
        key: const ValueKey('section-trash-sheet'),
        children: [
          BookLeatherModalHeader(
            title: strings.sectionTrash,
            trailing: entries.isEmpty
                ? null
                : TextButton(
                    onPressed: _emptyTrash,
                    child: Text(strings.emptyTrash),
                  ),
            onClose: () => Navigator.pop(context),
          ),
          const Divider(height: 1),
          Expanded(
            child: entries.isEmpty
                ? Center(child: Text(strings.sectionTrashEmpty))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[entries.length - 1 - index];
                      return _entry(context, entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _entry(BuildContext context, BookSectionTrashEntry entry) {
    final strings = AppStrings.of(context);
    final local = entry.deletedAt.toLocal();
    final material = MaterialLocalizations.of(context);
    return ListTile(
      key: ValueKey('trash-entry-${entry.id}'),
      leading: const CircleAvatar(child: Icon(Icons.delete_outline)),
      title: Text(entry.root.title),
      subtitle: Text(
        '${strings.sectionsInBook(entry.sections.length)} · '
        '${material.formatShortDate(local)} '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}',
      ),
      trailing: PopupMenuButton<_TrashAction>(
        onSelected: (action) => switch (action) {
          _TrashAction.restore => _restore(entry),
          _TrashAction.delete => _delete(entry),
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _TrashAction.restore,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restore),
              title: Text(strings.restoreSection),
            ),
          ),
          PopupMenuItem(
            value: _TrashAction.delete,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_forever_outlined),
              title: Text(strings.deletePermanently),
            ),
          ),
        ],
      ),
    );
  }

  void _restore(BookSectionTrashEntry entry) {
    widget.controller.restoreDeletedSection(entry.id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).sectionRestored)),
    );
  }

  Future<void> _delete(BookSectionTrashEntry entry) async {
    final confirmed = await _confirm(AppStrings.of(context).deleteForeverHint);
    if (!confirmed || !mounted) return;
    widget.controller.permanentlyDeleteSection(entry.id);
    setState(() {});
  }

  Future<void> _emptyTrash() async {
    final confirmed = await _confirm(AppStrings.of(context).emptyTrashHint);
    if (!confirmed || !mounted) return;
    widget.controller.emptySectionTrash();
    setState(() {});
  }

  Future<bool> _confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => BookLeatherDialog(
          title: Text(AppStrings.of(context).sectionTrash),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppStrings.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppStrings.of(context).deletePermanently),
            ),
          ],
        ),
      ) ??
      false;
}
