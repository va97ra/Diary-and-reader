import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/application/book_pdf_exporter.dart';
import 'package:dnevnik/features/books/application/book_pdf_font_assets.dart';
import 'package:dnevnik/features/books/data/book_export_file_service.dart';
import 'package:dnevnik/features/books/data/book_pdf_asset_font_loader.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class BookPdfPreviewPage extends StatefulWidget {
  const BookPdfPreviewPage({
    required this.project,
    this.fontLoader = const BookPdfAssetFontLoader(),
    this.fileSaver = const BookExportFileService(),
    super.key,
  });

  final BookProject project;
  final BookPdfFontLoader fontLoader;
  final BookExportFileSaver fileSaver;

  @override
  State<BookPdfPreviewPage> createState() => _BookPdfPreviewPageState();
}

class _BookPdfPreviewPageState extends State<BookPdfPreviewPage> {
  late Future<BookExportArtifact> _loading;
  BookExportArtifact? _artifact;

  @override
  void initState() {
    super.initState();
    _loading = _load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.pdfPreview),
        actions: [
          IconButton(
            key: const ValueKey('save-pdf-button'),
            tooltip: strings.savePdf,
            onPressed: _artifact == null ? null : _save,
            icon: const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: FutureBuilder<BookExportArtifact>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 42),
                    const SizedBox(height: 12),
                    Text(strings.pdfPreviewFailed, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: Text(strings.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final artifact = snapshot.data;
          if (artifact == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(strings.preparingPdf),
                ],
              ),
            );
          }
          return PdfPreview(
            key: const ValueKey('book-pdf-preview'),
            build: (_) async => artifact.bytes,
            initialPageFormat: BookPdfExporter.formatFor(widget.project),
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            allowSharing: false,
            allowPrinting: true,
            dynamicLayout: false,
            pdfFileName: '${widget.project.metadata.title}.pdf',
            maxPageWidth: 760,
            previewPageMargin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            scrollViewDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
          );
        },
      ),
    );
  }

  Future<BookExportArtifact> _load() async {
    final fonts = await widget.fontLoader.load();
    final artifact = await BookPdfExporter.create(
      project: widget.project,
      fontAssets: fonts,
    );
    if (mounted) setState(() => _artifact = artifact);
    return artifact;
  }

  void _retry() {
    setState(() {
      _artifact = null;
      _loading = _load();
    });
  }

  Future<void> _save() async {
    final strings = AppStrings.of(context);
    try {
      final saved = await widget.fileSaver.save(
        artifact: _artifact!,
        bookTitle: widget.project.metadata.title,
      );
      if (!mounted || !saved) return;
      _showMessage(strings.pdfSaved);
    } on Exception {
      if (mounted) _showMessage(strings.bookExportFailed);
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1600),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
