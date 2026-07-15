import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:flutter/material.dart';

class BookExportSheet extends StatelessWidget {
  const BookExportSheet({required this.onSelected, super.key});

  final ValueChanged<BookExportFormat> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Text(
                strings.exportBook,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                key: const ValueKey('export-book-epub'),
                leading: Icon(Icons.menu_book_outlined, color: colors.primary),
                title: Text(strings.exportEpub),
                subtitle: Text(strings.exportEpubHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onSelected(BookExportFormat.epub),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Text(
                strings.moreExportFormatsLater,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
