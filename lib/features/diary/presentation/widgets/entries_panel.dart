import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/diary/application/diary_controller.dart';
import 'package:dnevnik/features/diary/domain/diary_entry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EntriesPanel extends StatelessWidget {
  const EntriesPanel({
    required this.controller,
    this.closeAfterSelection = false,
    super.key,
  });

  final DiaryController controller;
  final bool closeAfterSelection;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Material(
      color: AppTheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              title: Text(
                strings.entries,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              trailing: IconButton(
                tooltip: strings.newEntry,
                onPressed: () => controller.addEntry(strings.newEntry),
                icon: const Icon(Icons.note_add_outlined),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: controller.entries.length,
                itemBuilder: (context, index) {
                  final entry = controller.entries[index];
                  return _EntryTile(
                    entry: entry,
                    isActive: controller.activeEntry?.id == entry.id,
                    onTap: () {
                      controller.selectEntry(entry.id);
                      if (closeAfterSelection) Navigator.of(context).pop();
                    },
                    onDelete: () => _confirmDelete(context, entry),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, DiaryEntry entry) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteEntry),
        content: Text(strings.deleteQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.deleteEntry),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      controller.deleteEntry(entry.id, fallbackTitle: strings.newEntry);
    }
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.entry,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  final DiaryEntry entry;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ListTile(
      selected: isActive,
      selectedTileColor: AppTheme.accent.withValues(alpha: 0.12),
      leading: Icon(
        Icons.circle,
        size: 10,
        color: isActive ? AppTheme.accent : Colors.blueGrey,
      ),
      title: Text(
        entry.title.isEmpty ? AppStrings.of(context).newEntry : entry.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(DateFormat.yMMMd(locale).add_Hm().format(entry.createdAt)),
      trailing: IconButton(
        tooltip: AppStrings.of(context).deleteEntry,
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline, size: 20),
      ),
      onTap: onTap,
    );
  }
}
