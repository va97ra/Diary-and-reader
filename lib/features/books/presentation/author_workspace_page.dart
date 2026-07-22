import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_docx_exporter.dart';
import 'package:dnevnik/features/books/application/book_epub_exporter.dart';
import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/application/book_fb2_exporter.dart';
import 'package:dnevnik/features/books/application/book_html_exporter.dart';
import 'package:dnevnik/features/books/application/book_image_file.dart';
import 'package:dnevnik/features/books/application/book_manuscript_search.dart';
import 'package:dnevnik/features/books/application/book_markdown_exporter.dart';
import 'package:dnevnik/features/books/application/book_pdf_font_assets.dart';
import 'package:dnevnik/features/books/application/book_project_archive_codec.dart';
import 'package:dnevnik/features/books/application/book_txt_exporter.dart';
import 'package:dnevnik/features/books/data/book_export_file_service.dart';
import 'package:dnevnik/features/books/data/book_image_file_service.dart';
import 'package:dnevnik/features/books/data/book_pdf_asset_font_loader.dart';
import 'package:dnevnik/features/books/data/book_project_backup_file_service.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/manuscript_statistics.dart';
import 'package:dnevnik/features/books/presentation/book_export_sheet.dart';
import 'package:dnevnik/features/books/presentation/book_manuscript_search_sheet.dart';
import 'package:dnevnik/features/books/presentation/book_pdf_preview_page.dart';
import 'package:dnevnik/features/books/presentation/book_version_history_sheet.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_editor_metrics.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_focus_mode_bar.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_formatting_toolbar.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_navigator.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_properties_panel.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_rename_title_dialog.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_section_editor.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_workspace_app_bar.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_writer_context_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class AuthorWorkspacePage extends StatefulWidget {
  const AuthorWorkspacePage({
    required this.controller,
    this.exportFileSaver = const BookExportFileService(),
    this.backupFileGateway = const BookProjectBackupFileService(),
    this.pdfFontLoader = const BookPdfAssetFontLoader(),
    this.imageFileGateway = const BookImageFileService(),
    super.key,
  });

  final AuthorWorkspaceController controller;
  final BookExportFileSaver exportFileSaver;
  final BookProjectBackupFileGateway backupFileGateway;
  final BookPdfFontLoader pdfFontLoader;
  final BookImageFileGateway imageFileGateway;

  @override
  State<AuthorWorkspacePage> createState() => _AuthorWorkspacePageState();
}

class _AuthorWorkspacePageState extends State<AuthorWorkspacePage> {
  QuillController? _editorController;
  final _sectionEditorKeys = <String, GlobalKey<BookSectionEditorState>>{};
  BookManuscriptMatch? _pendingSearchMatch;
  bool _isFocusMode = false;
  bool _isA4Preview = false;
  final _editorMetrics = <String, BookEditorMetrics>{};

  @override
  Widget build(BuildContext context) {
    final project = widget.controller.activeProject!;
    assert(!project.isReadOnly, 'Imported books open directly in the reader.');
    final section = project.activeSection!;
    final metrics =
        _editorMetrics[section.id] ??
        BookEditorMetrics(
          words: ManuscriptStatistics.fromDocument(section.content).words,
          activePage: 1,
          pageCount: 1,
        );
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 700;
        return PopScope(
          canPop: !_isFocusMode,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _isFocusMode) {
              setState(() => _isFocusMode = false);
            }
          },
          child: Scaffold(
            appBar: _isFocusMode
                ? null
                : BookWorkspaceAppBar(
                    bookTitle: project.metadata.title,
                    sectionTitle: section.title,
                    metrics: metrics,
                    saveState: widget.controller.saveState,
                    onRenameBook: _renameBook,
                    onRenameSection: _renameSection,
                    onRetrySave: widget.controller.flush,
                    onFocusMode: _toggleFocusMode,
                    onAction: _handleWorkspaceAction,
                  ),
            body: Column(
              children: [
                if (_isFocusMode)
                  BookFocusModeBar(
                    saveState: widget.controller.saveState,
                    onRetrySave: widget.controller.flush,
                    onExit: _toggleFocusMode,
                  ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: BookSectionEditor(
                          key: _sectionEditorKeys.putIfAbsent(
                            section.id,
                            GlobalKey<BookSectionEditorState>.new,
                          ),
                          section: section,
                          pageFormat: project.layoutSettings.pageFormat,
                          paragraphSettings: project.paragraphSettings,
                          assets: project.assets,
                          showToolbar: false,
                          usePagedLayout: isTablet || _isA4Preview,
                          compactA4Preview: !isTablet && _isA4Preview,
                          onExitCompactPreview: _toggleA4Preview,
                          onInsertImage: _insertImage,
                          onInsertPageBreak: _insertPageBreak,
                          showPageNavigation: !_isFocusMode,
                          viewMode: project.layoutSettings.viewMode,
                          onMetricsChanged: (metrics) =>
                              _handleEditorMetrics(section.id, metrics),
                          onTitleChanged: widget.controller.updateSectionTitle,
                          onContentChanged:
                              widget.controller.updateSectionContent,
                          onControllerReady: _handleEditorControllerReady,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _isFocusMode
                ? null
                : BookWriterContextBar(
                    onStructure: _showManuscript,
                    onUndo: () => _editorController?.undo(),
                    onRedo: () => _editorController?.redo(),
                    onFormatting: _showFormatting,
                    onSettings: _showWriterSettings,
                  ),
          ),
        );
      },
    );
  }

  void _handleEditorMetrics(String sectionId, BookEditorMetrics metrics) {
    if (_editorMetrics[sectionId] == metrics) return;
    if (!mounted) return;
    setState(() => _editorMetrics[sectionId] = metrics);
  }

  Future<void> _handleWorkspaceAction(BookWorkspaceAction action) {
    switch (action) {
      case BookWorkspaceAction.search:
        return _showManuscriptSearch();
      case BookWorkspaceAction.export:
        return _showExportSheet();
      case BookWorkspaceAction.preview:
        return _openReader();
      case BookWorkspaceAction.history:
        return _showVersionHistory();
      case BookWorkspaceAction.backup:
        return _backupProject();
      case BookWorkspaceAction.restore:
        return _restoreProjectBackup();
    }
  }

  void _toggleFocusMode() => setState(() {
    if (!_isFocusMode && _isA4Preview) _isA4Preview = false;
    _isFocusMode = !_isFocusMode;
  });

  void _toggleA4Preview() {
    final enabled = !_isA4Preview;
    setState(() => _isA4Preview = enabled);
    if (!enabled) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppStrings.of(context).a4PreviewHint),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  Future<void> _renameBook() async {
    final project = widget.controller.activeProject;
    if (project == null || project.isReadOnly) return;
    final strings = AppStrings.of(context);
    final title = await showDialog<String>(
      context: context,
      builder: (_) => BookRenameTitleDialog(
        initialTitle: project.metadata.title,
        label: strings.bookTitle,
        fieldKey: const ValueKey('writer-book-title-field'),
        saveKey: const ValueKey('writer-book-title-save'),
        strings: strings,
      ),
    );
    if (title == null || !mounted) return;
    final current = widget.controller.activeProject;
    if (current == null || current.isReadOnly) return;
    widget.controller.updateMetadata(current.metadata.copyWith(title: title));
    await widget.controller.flush();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(strings.saved)));
  }

  Future<void> _renameSection() async {
    final section = widget.controller.activeSection;
    if (section == null ||
        (widget.controller.activeProject?.isReadOnly ?? true)) {
      return;
    }
    final strings = AppStrings.of(context);
    final title = await showDialog<String>(
      context: context,
      builder: (_) => BookRenameTitleDialog(
        initialTitle: section.title,
        label: strings.chapterTitle,
        fieldKey: const ValueKey('writer-section-title-field'),
        saveKey: const ValueKey('writer-section-title-save'),
        strings: strings,
      ),
    );
    if (title == null || !mounted) return;
    widget.controller.updateSectionTitle(title);
    await widget.controller.flush();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(strings.saved)));
  }

  Future<void> _showManuscriptSearch() async {
    final project = widget.controller.activeProject;
    if (project == null || project.isReadOnly) return;
    final request = await showModalBottomSheet<BookReplaceRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: BookManuscriptSearchSheet(
          project: project,
          onOpenMatch: _openSearchMatch,
        ),
      ),
    );
    if (!mounted || request == null) return;
    final count = widget.controller.replaceAllInManuscript(
      request.query,
      request.replacement,
      caseSensitive: request.caseSensitive,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).replacementsMade(count))),
    );
  }

  void _openSearchMatch(BookManuscriptMatch match) {
    _pendingSearchMatch = match;
    if (_isA4Preview) setState(() => _isA4Preview = false);
    widget.controller.selectSection(match.sectionId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSearchMatch());
  }

  void _handleEditorControllerReady(QuillController controller) {
    _editorController = controller;
    if (_pendingSearchMatch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSearchMatch());
    }
  }

  void _revealSearchMatch() {
    if (!mounted) return;
    final match = _pendingSearchMatch;
    final activeSection = widget.controller.activeSection;
    if (match == null || activeSection?.id != match.sectionId) return;
    final editor = _sectionEditorKeys[match.sectionId]?.currentState;
    if (editor == null) return;
    _pendingSearchMatch = null;
    editor.revealTextRange(match.offset, match.length);
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

  Future<void> _showWriterSettings() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.of(context).writerSettings,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.tonalIcon(
              key: const ValueKey('writer-a4-preview-action'),
              onPressed: () {
                Navigator.pop(sheetContext);
                _toggleA4Preview();
              },
              icon: Icon(
                _isA4Preview
                    ? Icons.edit_note_outlined
                    : Icons.description_outlined,
              ),
              label: Text(
                _isA4Preview
                    ? AppStrings.of(context).comfortableWriting
                    : AppStrings.of(context).a4Preview,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: BookPropertiesPanel(controller: widget.controller)),
        ],
      ),
    ),
  );

  Future<void> _showFormatting() async {
    final controller = _editorController;
    if (controller == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.9,
        child: BookFormattingSheet(
          workspaceController: widget.controller,
          controller: controller,
          paragraphSettings: widget.controller.activeProject!.paragraphSettings,
          onInsertImage: () {
            Navigator.pop(sheetContext);
            _insertImage();
          },
          onInsertPageBreak: () {
            Navigator.pop(sheetContext);
            _insertPageBreak();
          },
        ),
      ),
    );
  }

  Future<void> _insertImage() async {
    final file = await widget.imageFileGateway.open();
    if (!mounted || file == null) return;
    final asset = BookImageFileCodec.createAsset(file);
    final controller = _editorController;
    if (asset == null || controller == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).imageInsertFailed)),
      );
      return;
    }
    final selection = controller.selection;
    final offset = selection.extentOffset.clamp(
      0,
      controller.document.length - 1,
    );
    controller.replaceText(
      offset,
      0,
      BlockEmbed.custom(CustomBlockEmbed('bookImage', asset.id)),
      TextSelection.collapsed(offset: offset + 1),
    );
    widget.controller.addAsset(asset);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).imageInserted)),
    );
  }

  void _insertPageBreak() {
    final controller = _editorController;
    if (controller == null) return;
    final offset = controller.selection.extentOffset.clamp(
      0,
      controller.document.length - 1,
    );
    controller.replaceText(
      offset,
      0,
      BlockEmbed.custom(const CustomBlockEmbed('bookPageBreak', '1')),
      TextSelection.collapsed(offset: offset + 1),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).pageBreakInserted)),
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
          readerSettings: widget.controller.readerSettings,
          onSettingsChanged: widget.controller.updateReaderSettings,
          onProgressChanged: widget.controller.updateReaderProgress,
          onAnnotationsChanged: widget.controller.updateReaderAnnotations,
        ),
      ),
    );
    await widget.controller.flush();
  }
}
