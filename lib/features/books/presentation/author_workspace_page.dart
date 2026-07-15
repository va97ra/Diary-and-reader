import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_docx_exporter.dart';
import 'package:dnevnik/features/books/application/book_epub_exporter.dart';
import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/application/book_fb2_exporter.dart';
import 'package:dnevnik/features/books/application/book_html_exporter.dart';
import 'package:dnevnik/features/books/application/book_markdown_exporter.dart';
import 'package:dnevnik/features/books/application/book_pdf_font_assets.dart';
import 'package:dnevnik/features/books/application/book_project_archive_codec.dart';
import 'package:dnevnik/features/books/application/book_txt_exporter.dart';
import 'package:dnevnik/features/books/data/book_export_file_service.dart';
import 'package:dnevnik/features/books/data/book_pdf_asset_font_loader.dart';
import 'package:dnevnik/features/books/data/book_project_backup_file_service.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/presentation/book_export_sheet.dart';
import 'package:dnevnik/features/books/presentation/book_pdf_preview_page.dart';
import 'package:dnevnik/features/books/presentation/book_version_history_sheet.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_formatting_toolbar.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_navigator.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_properties_panel.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_section_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

enum _ProjectDataAction { history, backup, restore }

class AuthorWorkspacePage extends StatefulWidget {
  const AuthorWorkspacePage({
    required this.controller,
    this.exportFileSaver = const BookExportFileService(),
    this.backupFileGateway = const BookProjectBackupFileService(),
    this.pdfFontLoader = const BookPdfAssetFontLoader(),
    super.key,
  });

  final AuthorWorkspaceController controller;
  final BookExportFileSaver exportFileSaver;
  final BookProjectBackupFileGateway backupFileGateway;
  final BookPdfFontLoader pdfFontLoader;

  @override
  State<AuthorWorkspacePage> createState() => _AuthorWorkspacePageState();
}

class _AuthorWorkspacePageState extends State<AuthorWorkspacePage> {
  QuillController? _editorController;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = widget.controller.activeProject!;
    final section = project.activeSection!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1500;
        final isTablet = constraints.maxWidth >= 700;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.metadata.title),
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                key: const ValueKey('export-book-button'),
                tooltip: strings.exportBook,
                onPressed: _showExportSheet,
                icon: const Icon(Icons.ios_share_outlined),
              ),
              IconButton(
                key: const ValueKey('open-book-reader'),
                tooltip: strings.reader,
                onPressed: _openReader,
                icon: const Icon(Icons.chrome_reader_mode_outlined),
              ),
              PopupMenuButton<_ProjectDataAction>(
                key: const ValueKey('project-data-menu'),
                tooltip: strings.projectData,
                icon: const Icon(Icons.more_vert),
                onSelected: _handleProjectDataAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _ProjectDataAction.history,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history),
                      title: Text(strings.versionHistory),
                    ),
                  ),
                  PopupMenuItem(
                    value: _ProjectDataAction.backup,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.download_outlined),
                      title: Text(strings.backupProject),
                    ),
                  ),
                  PopupMenuItem(
                    value: _ProjectDataAction.restore,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.upload_file_outlined),
                      title: Text(strings.restoreProjectBackup),
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: strings.language,
                onPressed: () => widget.controller.setLanguage(
                  widget.controller.languageCode == 'ru' ? 'en' : 'ru',
                ),
                icon: Text(widget.controller.languageCode.toUpperCase()),
              ),
              if (!isDesktop)
                IconButton(
                  tooltip: strings.properties,
                  onPressed: _showProperties,
                  icon: const Icon(Icons.tune),
                ),
            ],
          ),
          body: Row(
            children: [
              if (isTablet)
                SizedBox(
                  width: isDesktop ? 290 : 250,
                  child: BookNavigator(controller: widget.controller),
                ),
              Expanded(
                child: BookSectionEditor(
                  key: ValueKey(section.id),
                  section: section,
                  pageFormat: project.layoutSettings.pageFormat,
                  paragraphSettings: project.paragraphSettings,
                  showToolbar: isTablet,
                  saveState: widget.controller.saveState,
                  viewMode: project.layoutSettings.viewMode,
                  onViewModeChanged: (viewMode) =>
                      widget.controller.updateLayoutSettings(
                        project.layoutSettings.copyWith(viewMode: viewMode),
                      ),
                  onTitleChanged: widget.controller.updateSectionTitle,
                  onContentChanged: widget.controller.updateSectionContent,
                  onControllerReady: (controller) =>
                      _editorController = controller,
                ),
              ),
              if (isDesktop)
                SizedBox(
                  width: 300,
                  child: BookPropertiesPanel(controller: widget.controller),
                ),
            ],
          ),
          bottomNavigationBar: isTablet
              ? null
              : NavigationBar(
                  selectedIndex: 1,
                  onDestinationSelected: (index) {
                    if (index == 0) _showManuscript();
                    if (index == 2) _showFormatting();
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.account_tree_outlined),
                      label: strings.manuscript,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.edit_outlined),
                      label: strings.editor,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.text_format),
                      label: strings.formatting,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _showManuscript() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.82,
      child: BookNavigator(
        controller: widget.controller,
        closeAfterSelection: true,
      ),
    ),
  );

  Future<void> _showProperties() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.82,
      child: BookPropertiesPanel(controller: widget.controller),
    ),
  );

  Future<void> _showFormatting() async {
    final controller = _editorController;
    if (controller == null) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => BookFormattingSheet(
        controller: controller,
        paragraphSettings: widget.controller.activeProject!.paragraphSettings,
      ),
    );
  }

  Future<void> _showExportSheet() async {
    await widget.controller.flush();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => BookExportSheet(
        onSelected: (format) {
          Navigator.of(sheetContext).pop();
          switch (format) {
            case BookExportFormat.epub:
              _exportArtifact(BookEpubExporter.create);
            case BookExportFormat.fb2:
              _exportArtifact(BookFb2Exporter.create);
            case BookExportFormat.fb2Zip:
              _exportArtifact(BookFb2Exporter.createZip);
            case BookExportFormat.pdf:
              _openPdfPreview();
            case BookExportFormat.docx:
              _exportArtifact(BookDocxExporter.create);
            case BookExportFormat.html:
              _exportArtifact(BookHtmlExporter.create);
            case BookExportFormat.markdown:
              _exportArtifact(BookMarkdownExporter.create);
            case BookExportFormat.txt:
              _exportArtifact(BookTxtExporter.create);
          }
        },
      ),
    );
  }

  Future<void> _handleProjectDataAction(_ProjectDataAction action) async {
    switch (action) {
      case _ProjectDataAction.history:
        return _showVersionHistory();
      case _ProjectDataAction.backup:
        return _backupProject();
      case _ProjectDataAction.restore:
        return _restoreProjectBackup();
    }
  }

  Future<void> _showVersionHistory() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.84,
      child: BookVersionHistorySheet(controller: widget.controller),
    ),
  );

  Future<void> _backupProject() async {
    final strings = AppStrings.of(context);
    try {
      await widget.controller.flush();
      final project = widget.controller.activeProject;
      if (project == null) return;
      final saved = await widget.backupFileGateway.save(
        archive: BookProjectArchiveCodec.encode(project),
        bookTitle: project.metadata.title,
      );
      if (mounted && saved) _showMessage(strings.projectBackupSaved);
    } on Exception {
      if (mounted) _showMessage(strings.projectBackupFailed);
    }
  }

  Future<void> _restoreProjectBackup() async {
    final strings = AppStrings.of(context);
    try {
      final encoded = await widget.backupFileGateway.open();
      if (encoded == null || !mounted) return;
      final imported = BookProjectArchiveCodec.decode(encoded);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(strings.restoreProjectBackup),
          content: Text(
            '${imported.metadata.title}\n\n${strings.confirmProjectRestore}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              key: const ValueKey('confirm-project-restore'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.restoreVersion),
            ),
          ],
        ),
      );
      if (!(confirmed ?? false) || !mounted) return;
      await widget.controller.importProject(
        imported,
        safetyLabel: strings.safetyVersionLabel,
      );
      if (mounted) _showMessage(strings.projectRestored);
    } on FormatException {
      if (mounted) _showMessage(strings.projectRestoreFailed);
    } on Exception {
      if (mounted) _showMessage(strings.projectRestoreFailed);
    }
  }

  Future<void> _exportArtifact(
    BookExportArtifact Function(BookProject project) createArtifact,
  ) async {
    final strings = AppStrings.of(context);
    final project = widget.controller.activeProject;
    if (project == null) return;
    try {
      final artifact = createArtifact(project);
      final saved = await widget.exportFileSaver.save(
        artifact: artifact,
        bookTitle: project.metadata.title,
      );
      if (!mounted || !saved) return;
      _showMessage(strings.bookExported);
    } on Exception {
      if (mounted) _showMessage(strings.bookExportFailed);
    }
  }

  Future<void> _openPdfPreview() async {
    final project = widget.controller.activeProject;
    if (project == null || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BookPdfPreviewPage(
          project: project,
          fontLoader: widget.pdfFontLoader,
          fileSaver: widget.exportFileSaver,
        ),
      ),
    );
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

  Future<void> _openReader() async {
    await widget.controller.flush();
    if (!mounted) return;
    final project = widget.controller.activeProject;
    if (project == null || project.sections.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BookReaderPage(
          project: project,
          onSettingsChanged: widget.controller.updateReaderSettings,
          onProgressChanged: widget.controller.updateReaderProgress,
          onAnnotationsChanged: widget.controller.updateReaderAnnotations,
        ),
      ),
    );
    await widget.controller.flush();
  }
}
