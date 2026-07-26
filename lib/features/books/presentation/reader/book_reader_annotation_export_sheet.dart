import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_reader_annotation_exporter.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:flutter/material.dart';

class BookReaderAnnotationExportSheet extends StatelessWidget {
  const BookReaderAnnotationExportSheet({required this.onSelected, super.key});

  final ValueChanged<BookReaderAnnotationExportFormat> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookLeatherModalHeader(
              title: strings.exportAnnotations,
              onClose: () => Navigator.maybePop(context),
              closeKey: const ValueKey('reader-export-close'),
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
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
