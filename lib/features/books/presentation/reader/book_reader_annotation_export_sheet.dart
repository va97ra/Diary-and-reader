import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_reader_annotation_exporter.dart';
import 'package:flutter/material.dart';

class BookReaderAnnotationExportSheet extends StatelessWidget {
  const BookReaderAnnotationExportSheet({required this.onSelected, super.key});

  final ValueChanged<BookReaderAnnotationExportFormat> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                    child: Text(
                      strings.exportAnnotations,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('reader-export-close'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            ListTile(
              key: const ValueKey('reader-export-markdown'),
              leading: const Icon(Icons.description_outlined),
              title: Text(strings.exportMarkdown),
              subtitle: Text(strings.exportMarkdownHint),
              onTap: () =>
                  onSelected(BookReaderAnnotationExportFormat.markdown),
            ),
            ListTile(
              key: const ValueKey('reader-export-json'),
              leading: const Icon(Icons.data_object),
              title: Text(strings.exportJson),
              subtitle: Text(strings.exportJsonHint),
              onTap: () => onSelected(BookReaderAnnotationExportFormat.json),
            ),
          ],
        ),
      ),
    );
  }
}
