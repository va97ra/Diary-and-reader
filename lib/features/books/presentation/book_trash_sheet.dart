import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section_trash.dart';
import 'package:dnevnik/features/books/domain/book_text_trash.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:flutter/material.dart';

enum _TrashAction { restore, delete }

/// Deleted chapters and deleted text of the book, newest first.
class BookTrashSheet extends StatefulWidget {
  const BookTrashSheet({required this.controller, super.key});

  final AuthorWorkspaceController controller;

  @override
  State<BookTrashSheet> createState() => _BookTrashSheetState();
}

class _BookTrashSheetState extends State<BookTrashSheet> {
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = widget.controller.activeProject;
    final entries = <(DateTime, Widget)>[
      for (final entry
          in project?.sectionTrash ?? const <BookSectionTrashEntry>[])
        (entry.deletedAt, _sectionEntry(context, entry)),
      for (final entry in project?.textTrash ?? const <BookTextTrashEntry>[])
        (entry.deletedAt, _textEntry(context, project!, entry)),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    return SafeArea(
      child: Column(
        key: const ValueKey('trash-sheet'),
        children: [
          BookLeatherModalHeader(
            title: strings.trash,
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
                ? Center(child: Text(strings.trashEmpty))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) => entries[index].$2,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionEntry(BuildContext context, BookSectionTrashEntry entry) {
    final strings = AppStrings.of(context);
    return _TrashTile(
      key: ValueKey('trash-entry-${entry.id}'),
      icon: Icons.article_outlined,
      title: entry.root.title,
      subtitle:
          '${strings.sectionsInBook(entry.sections.length)} · '
          '${_when(context, entry.deletedAt)}',
      restoreLabel: strings.restoreSection,
      onRestore: () => _restore(
        () => widget.controller.restoreDeletedSection(entry.id),
        strings.sectionRestored,
      ),
      onDelete: () =>
          _delete(() => widget.controller.permanentlyDeleteSection(entry.id)),
    );
  }

  Widget _textEntry(
    BuildContext context,
    BookProject project,
    BookTextTrashEntry entry,
  ) {
    final strings = AppStrings.of(context);
    final text = richDocumentPlainText(
      entry.content,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
    final chapter = project.sections
        .where((section) => section.id == entry.sectionId)
        .firstOrNull;
    return _TrashTile(
      key: ValueKey('trash-entry-${entry.id}'),
      icon: text.isEmpty && entry.hasEmbed
          ? Icons.image_outlined
          : Icons.notes_outlined,
      title: text.isEmpty ? strings.deletedPicture : '«$text»',
      subtitle: [
        if (chapter != null) chapter.title,
        _when(context, entry.deletedAt),
      ].join(' · '),
      restoreLabel: strings.restoreDeletedText,
      onRestore: () => _restore(
        () => widget.controller.restoreDeletedText(entry.id),
        strings.textRestored,
      ),
      onDelete: () =>
          _delete(() => widget.controller.permanentlyDeleteText(entry.id)),
    );
  }

  String _when(BuildContext context, DateTime moment) {
    final local = moment.toLocal();
    final material = MaterialLocalizations.of(context);
    return '${material.formatShortDate(local)} '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  void _restore(VoidCallback restore, String message) {
    restore();
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _delete(VoidCallback delete) async {
    final confirmed = await _confirm(AppStrings.of(context).deleteForeverHint);
    if (!confirmed || !mounted) return;
    delete();
    setState(() {});
  }

  Future<void> _emptyTrash() async {
    final confirmed = await _confirm(AppStrings.of(context).emptyTrashHint);
    if (!confirmed || !mounted) return;
    widget.controller.emptyTrash();
    setState(() {});
  }

  Future<bool> _confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => BookLeatherDialog(
          title: Text(AppStrings.of(context).trash),
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

class _TrashTile extends StatelessWidget {
  const _TrashTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.restoreLabel,
    required this.onRestore,
    required this.onDelete,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String restoreLabel;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ListTile(
      leading: CircleAvatar(child: Icon(icon)),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: PopupMenuButton<_TrashAction>(
        tooltip: strings.more,
        onSelected: (action) => switch (action) {
          _TrashAction.restore => onRestore(),
          _TrashAction.delete => onDelete(),
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _TrashAction.restore,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restore),
              title: Text(restoreLabel),
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
}
