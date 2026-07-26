import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:flutter/material.dart';

class BookExportSheet extends StatelessWidget {
  const BookExportSheet({required this.onSelected, super.key});

  final ValueChanged<BookExportFormat> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: SingleChildScrollView(
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
                          strings.exportBook,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('book-export-close'),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                _SectionLabel(text: strings.readerExportFormats),
                _ExportTile(
                  tileKey: const ValueKey('export-book-epub'),
                  icon: Icons.menu_book_outlined,
                  title: strings.exportEpub,
                  subtitle: strings.exportEpubHint,
                  onTap: () => onSelected(BookExportFormat.epub),
                ),
                _ExportTile(
                  tileKey: const ValueKey('export-book-fb2'),
                  icon: Icons.auto_stories_outlined,
                  title: strings.exportFb2,
                  subtitle: strings.exportFb2Hint,
                  onTap: () => onSelected(BookExportFormat.fb2),
                ),
                _ExportTile(
                  tileKey: const ValueKey('export-book-fb2-zip'),
                  icon: Icons.folder_zip_outlined,
                  title: strings.exportFb2Zip,
                  subtitle: strings.exportFb2ZipHint,
                  onTap: () => onSelected(BookExportFormat.fb2Zip),
                ),
                _SectionLabel(text: strings.printExportFormats),
                _ExportTile(
                  tileKey: const ValueKey('export-book-pdf'),
                  icon: Icons.picture_as_pdf_outlined,
                  title: strings.exportPdf,
                  subtitle: strings.exportPdfHint,
                  onTap: () => onSelected(BookExportFormat.pdf),
                ),
                _ExportTile(
                  tileKey: const ValueKey('export-book-docx'),
                  icon: Icons.description_outlined,
                  title: strings.exportDocx,
                  subtitle: strings.exportDocxHint,
                  onTap: () => onSelected(BookExportFormat.docx),
                ),
                _SectionLabel(text: strings.textExportFormats),
                _ExportTile(
                  tileKey: const ValueKey('export-book-html'),
                  icon: Icons.language_outlined,
                  title: strings.exportHtml,
                  subtitle: strings.exportHtmlHint,
                  onTap: () => onSelected(BookExportFormat.html),
                ),
                _ExportTile(
                  tileKey: const ValueKey('export-book-markdown'),
                  icon: Icons.code_outlined,
                  title: strings.exportMarkdown,
                  subtitle: strings.exportMarkdownHint,
                  onTap: () => onSelected(BookExportFormat.markdown),
                ),
                _ExportTile(
                  tileKey: const ValueKey('export-book-txt'),
                  icon: Icons.subject_outlined,
                  title: strings.exportTxt,
                  subtitle: strings.exportTxtHint,
                  onTap: () => onSelected(BookExportFormat.txt),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      key: tileKey,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
