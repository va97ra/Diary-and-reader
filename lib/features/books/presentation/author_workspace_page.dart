import 'dart:convert';

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
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_image_placement.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/manuscript_statistics.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/book_export_sheet.dart';
import 'package:dnevnik/features/books/presentation/book_manuscript_search_sheet.dart';
import 'package:dnevnik/features/books/presentation/book_pdf_preview_page.dart';
import 'package:dnevnik/features/books/presentation/book_section_trash_sheet.dart';
import 'package:dnevnik/features/books/presentation/book_version_history_sheet.dart';
import 'package:dnevnik/features/books/presentation/book_writing_statistics_sheet.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_adaptive_control_shell.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_editor_metrics.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_focus_mode_bar.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_formatting_toolbar.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_image_settings_sheet.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_navigator.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_properties_panel.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_rename_title_dialog.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_save_status.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_section_editor.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_sheet_keyboard_dismiss.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_workspace_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

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

class _AuthorWorkspacePageState extends State<AuthorWorkspacePage>
    with WidgetsBindingObserver {
  QuillController? _editorController;
  final _sectionEditorKeys = <String, GlobalKey<BookSectionEditorState>>{};
  BookManuscriptMatch? _pendingSearchMatch;
  bool _isFocusMode = false;
  bool _isA4Preview = false;
  final _editorMetrics = <String, BookEditorMetrics>{};
  DateTime _writingSessionStartedAt = DateTime.now();
  DateTime? _lastWritingActivity;
  Duration _activeWritingDuration = Duration.zero;
  late int _writingSessionStartWords;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _writingSessionStartWords = _projectWordCount();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _commitWritingSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
            if (didPop) {
              _commitWritingSession(deferNotification: true);
              return;
            }
            if (_isFocusMode) {
              setState(() => _isFocusMode = false);
            }
          },
          child: BookAdaptiveControlShell(
            panelsVisible: !_isFocusMode,
            compactTopPanel: _buildCompactWriterTop(
              project: project,
              section: section,
              metrics: metrics,
            ),
            compactBottomPanel: _buildCompactWriterBottom(),
            wideStartPanel: _buildWideWriterStart(
              project: project,
              section: section,
              metrics: metrics,
            ),
            wideEndPanel: _buildWideWriterEnd(),
            content: Column(
              children: [
                if (_isFocusMode)
                  BookFocusModeBar(
                    saveState: widget.controller.saveState,
                    onRetrySave: widget.controller.flush,
                    onExit: _toggleFocusMode,
                  ),
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
                    onImageTap: _showImageSettings,
                    onInsertPageBreak: _insertPageBreak,
                    showPageNavigation: !_isFocusMode,
                    viewMode: project.layoutSettings.viewMode,
                    onMetricsChanged: (metrics) =>
                        _handleEditorMetrics(section.id, metrics),
                    showChapterTitleOnPage:
                        _isA4Preview &&
                        project.layoutSettings.showChapterTitlesInBody,
                    onTitleChanged: widget.controller.updateSectionTitle,
                    onContentChanged: _handleContentChanged,
                    onControllerReady: _handleEditorControllerReady,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactWriterTop({
    required BookProject project,
    required BookSection section,
    required BookEditorMetrics metrics,
  }) {
    final strings = AppStrings.of(context);
    return SizedBox(
      key: const ValueKey('writer-top-panel'),
      height: 82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
        child: Row(
          children: [
            BookPanelIconAction(
              key: const ValueKey('writer-back-action'),
              icon: Icons.arrow_back,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BookPanelTitleAction(
                    key: const ValueKey('writer-book-title-action'),
                    title: project.metadata.title,
                    label: strings.bookTitle,
                    primary: true,
                    onPressed: _renameBook,
                  ),
                  BookPanelTitleAction(
                    key: const ValueKey('writer-section-title-action'),
                    title: section.title,
                    label: strings.chapterTitle,
                    onPressed: _renameSection,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${strings.words}: ${metrics.words} · '
                          '${strings.page} ${metrics.activePage}/${metrics.pageCount}',
                          key: const ValueKey('writer-header-metrics'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BookLeatherColors.mutedForeground,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                      BookSaveStatus(
                        state: widget.controller.saveState,
                        compact: true,
                        onRetry: widget.controller.flush,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactWriterBottom() {
    final strings = AppStrings.of(context);
    return SizedBox(
      key: const ValueKey('writer-context-bar'),
      height: 74,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _compactWriterAction(
              key: const ValueKey('writer-structure-action'),
              icon: Icons.account_tree_outlined,
              label: strings.structure,
              onPressed: _showManuscript,
            ),
            _compactWriterAction(
              key: const ValueKey('writer-formatting-action'),
              icon: Icons.text_format,
              label: strings.writerFormatting,
              onPressed: _showFormatting,
              selected: true,
            ),
            _compactWriterAction(
              key: const ValueKey('writer-hide-panels-button'),
              icon: Icons.fullscreen,
              label: strings.focusWriting,
              onPressed: _toggleFocusMode,
            ),
            _compactWriterAction(
              key: const ValueKey('writer-settings-action'),
              icon: Icons.tune,
              label: strings.settings,
              onPressed: _showWriterSettings,
            ),
            _compactWriterAction(
              key: const ValueKey('writer-more-menu'),
              icon: Icons.grid_view_rounded,
              label: strings.moreActions,
              onPressed: _showWorkspaceTools,
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactWriterAction({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool selected = false,
  }) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: BookPanelAction(
        key: key,
        icon: Icon(icon),
        label: label,
        onPressed: onPressed,
        selected: selected,
        compact: true,
        compactLabelLines: 2,
      ),
    ),
  );

  Widget _buildWideWriterStart({
    required BookProject project,
    required BookSection section,
    required BookEditorMetrics metrics,
  }) {
    final strings = AppStrings.of(context);
    return Column(
      key: const ValueKey('writer-left-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 9, 8, 4),
          child: Row(
            children: [
              BookPanelIconAction(
                key: const ValueKey('writer-back-action'),
                icon: Icons.arrow_back,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              BookPanelIconAction(
                key: const ValueKey('writer-hide-panels-button'),
                icon: Icons.fullscreen,
                tooltip: strings.focusWriting,
                onPressed: _toggleFocusMode,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BookPanelTitleAction(
                key: const ValueKey('writer-book-title-action'),
                title: project.metadata.title,
                label: strings.bookTitle,
                primary: true,
                onPressed: _renameBook,
              ),
              BookPanelTitleAction(
                key: const ValueKey('writer-section-title-action'),
                title: section.title,
                label: strings.chapterTitle,
                onPressed: _renameSection,
              ),
              const SizedBox(height: 7),
              Text(
                '${strings.words}: ${metrics.words}',
                key: const ValueKey('writer-header-metrics'),
                style: const TextStyle(
                  color: BookLeatherColors.mutedForeground,
                  fontSize: 10,
                ),
              ),
              Text(
                '${strings.page} ${metrics.activePage}/${metrics.pageCount}',
                style: const TextStyle(
                  color: BookLeatherColors.mutedForeground,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.centerLeft,
                child: BookSaveStatus(
                  state: widget.controller.saveState,
                  onRetry: widget.controller.flush,
                ),
              ),
            ],
          ),
        ),
        BookPanelSectionLabel(strings.manuscript),
        _wideWriterAction(
          key: const ValueKey('writer-structure-action'),
          icon: Icons.account_tree_outlined,
          label: strings.structure,
          onPressed: _showManuscript,
        ),
      ],
    );
  }

  Widget _buildWideWriterEnd() {
    final strings = AppStrings.of(context);
    return ListView(
      key: const ValueKey('writer-right-panel'),
      padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
      children: [
        BookPanelSectionLabel(strings.writerFormatting),
        _wideWriterAction(
          key: const ValueKey('writer-formatting-action'),
          icon: Icons.text_format,
          label: strings.writerFormatting,
          onPressed: _showFormatting,
          selected: true,
        ),
        _wideWriterAction(
          key: const ValueKey('writer-settings-action'),
          icon: Icons.tune,
          label: strings.settings,
          onPressed: _showWriterSettings,
        ),
        BookPanelSectionLabel(strings.moreActions),
        for (final action in BookWorkspaceAction.values)
          _workspaceActionButton(action),
      ],
    );
  }

  Widget _wideWriterAction({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool selected = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: BookPanelAction(
      key: key,
      icon: Icon(icon),
      label: label,
      onPressed: onPressed,
      selected: selected,
    ),
  );

  Widget _workspaceActionButton(
    BookWorkspaceAction action, {
    VoidCallback? onPressed,
  }) {
    final (icon, label) = _workspaceActionPresentation(action);
    return _wideWriterAction(
      key: ValueKey('writer-panel-${action.name}'),
      icon: icon,
      label: label,
      onPressed: onPressed ?? () => _handleWorkspaceAction(action),
    );
  }

  (IconData, String) _workspaceActionPresentation(BookWorkspaceAction action) {
    final strings = AppStrings.of(context);
    return switch (action) {
      BookWorkspaceAction.search => (
        Icons.manage_search,
        strings.findAndReplace,
      ),
      BookWorkspaceAction.statistics => (
        Icons.insights_outlined,
        strings.writingStatistics,
      ),
      BookWorkspaceAction.export => (
        Icons.ios_share_outlined,
        strings.exportBook,
      ),
      BookWorkspaceAction.preview => (
        Icons.chrome_reader_mode_outlined,
        strings.previewBook,
      ),
      BookWorkspaceAction.history => (Icons.history, strings.versionHistory),
      BookWorkspaceAction.trash => (Icons.delete_outline, strings.sectionTrash),
      BookWorkspaceAction.backup => (
        Icons.download_outlined,
        strings.backupProject,
      ),
      BookWorkspaceAction.restore => (
        Icons.upload_file_outlined,
        strings.restoreProjectBackup,
      ),
    };
  }

  Future<void> _showWorkspaceTools() => showBookLeatherBottomSheet<void>(
    context: context,
    builder: (sheetContext) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookLeatherModalHeader(
            title: AppStrings.of(context).moreActions,
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
          Flexible(
            child: GridView.count(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              crossAxisCount: 2,
              childAspectRatio: 1.75,
              mainAxisSpacing: bookModalGrid,
              crossAxisSpacing: bookModalGrid,
              children: [
                for (final action in BookWorkspaceAction.values)
                  Builder(
                    builder: (_) {
                      final (icon, label) = _workspaceActionPresentation(
                        action,
                      );
                      return BookPanelAction(
                        key: ValueKey('writer-panel-${action.name}'),
                        icon: Icon(icon),
                        label: label,
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _handleWorkspaceAction(action);
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void _handleEditorMetrics(String sectionId, BookEditorMetrics metrics) {
    if (_editorMetrics[sectionId] == metrics) return;
    if (!mounted) return;
    setState(() => _editorMetrics[sectionId] = metrics);
  }

  Future<void> _handleWorkspaceAction(BookWorkspaceAction action) {
    switch (action) {
      case BookWorkspaceAction.search:
        return _showManuscriptSearch();
      case BookWorkspaceAction.statistics:
        return _showWritingStatistics();
      case BookWorkspaceAction.export:
        return _showExportSheet();
      case BookWorkspaceAction.preview:
        return _openReader();
      case BookWorkspaceAction.history:
        return _showVersionHistory();
      case BookWorkspaceAction.trash:
        return _showSectionTrash();
      case BookWorkspaceAction.backup:
        return _backupProject();
      case BookWorkspaceAction.restore:
        return _restoreProjectBackup();
    }
  }

  void _handleContentChanged(RichDocument content) {
    final now = DateTime.now();
    final previous = _lastWritingActivity;
    if (previous == null) {
      _activeWritingDuration += const Duration(seconds: 1);
    } else {
      final gap = now.difference(previous);
      if (!gap.isNegative && gap <= const Duration(minutes: 2)) {
        _activeWritingDuration += gap;
      }
    }
    _lastWritingActivity = now;
    widget.controller.updateSectionContent(content);
  }

  int _projectWordCount() {
    final project = widget.controller.activeProject;
    if (project == null) return 0;
    return project.sections.fold(
      0,
      (total, section) =>
          total + ManuscriptStatistics.fromDocument(section.content).words,
    );
  }

  void _commitWritingSession({bool deferNotification = false}) {
    final project = widget.controller.activeProject;
    if (project != null && !project.isReadOnly) {
      final controller = widget.controller;
      final startedAt = _writingSessionStartedAt;
      final duration = _activeWritingDuration;
      final wordsAdded = (_projectWordCount() - _writingSessionStartWords)
          .clamp(0, 10000000);
      void record() => controller.recordWritingSession(
        project.id,
        startedAt: startedAt,
        duration: duration,
        wordsAdded: wordsAdded,
      );
      if (deferNotification) {
        WidgetsBinding.instance.addPostFrameCallback((_) => record());
      } else {
        record();
      }
    }
    _writingSessionStartedAt = DateTime.now();
    _writingSessionStartWords = _projectWordCount();
    _lastWritingActivity = null;
    _activeWritingDuration = Duration.zero;
  }

  Future<void> _showWritingStatistics() async {
    _commitWritingSession();
    await showBookLeatherBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BookSheetKeyboardDismiss(
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: BookWritingStatisticsSheet(controller: widget.controller),
        ),
      ),
    );
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
    final request = await showBookLeatherBottomSheet<BookReplaceRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => BookSheetKeyboardDismiss(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: BookManuscriptSearchSheet(
            project: project,
            onOpenMatch: _openSearchMatch,
          ),
        ),
      ),
    );
    if (!mounted || request == null) return;
    final strings = AppStrings.of(context);
    final count = await widget.controller.replaceAllInManuscriptSafely(
      request.query,
      request.replacement,
      caseSensitive: request.caseSensitive,
      safetyLabel: strings.automaticBeforeReplace,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.replacementsMade(count))));
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

  Future<void> _showManuscript() => showBookLeatherBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => BookSheetKeyboardDismiss(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
        ),
        child: BookNavigator(
          controller: widget.controller,
          closeAfterSelection: true,
        ),
      ),
    ),
  );

  Future<void> _showWriterSettings() => showBookLeatherBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => BookSheetKeyboardDismiss(
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookLeatherModalHeader(
              title: AppStrings.of(context).writerSettings,
              onClose: () => Navigator.pop(sheetContext),
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
            Expanded(
              child: BookPropertiesPanel(
                controller: widget.controller,
                onChooseCover: _chooseCover,
                onRemoveCover: widget.controller.clearCoverAsset,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _showFormatting() async {
    final controller = _editorController;
    if (controller == null) return;
    await showBookLeatherBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => BookSheetKeyboardDismiss(
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: BookFormattingSheet(
            workspaceController: widget.controller,
            controller: controller,
            paragraphSettings:
                widget.controller.activeProject!.paragraphSettings,
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
      ),
    );
  }

  Future<void> _insertImage() async {
    final asset = await _pickImageAsset();
    if (!mounted) return;
    final controller = _editorController;
    if (asset == null || controller == null) {
      return;
    }
    final selection = controller.selection;
    final offset = selection.extentOffset.clamp(
      0,
      controller.document.length - 1,
    );
    _insertImageAtOffset(
      controller,
      offset,
      BookImagePlacement(assetId: asset.id),
    );
    widget.controller.addAsset(asset);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).imageInserted)),
    );
  }

  Future<BookAsset?> _pickImageAsset() async {
    final file = await widget.imageFileGateway.open();
    if (!mounted || file == null) return null;
    final asset = BookImageFileCodec.createAsset(file);
    if (asset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).imageInsertFailed)),
      );
    }
    return asset;
  }

  Future<void> _chooseCover() async {
    final asset = await _pickImageAsset();
    if (asset == null || !mounted) return;
    widget.controller.setCoverAsset(asset);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context).coverUpdated)),
    );
  }

  Future<void> _showImageSettings(
    QuillController controller,
    int offset,
    BookImagePlacement placement,
  ) async {
    final editorState =
        _sectionEditorKeys[widget.controller.activeSection?.id]?.currentState;
    editorState?.suspendTextInputFocus();
    final cursorOffset = controller.selection.extentOffset.clamp(
      0,
      controller.document.length - 1,
    );
    var draft = placement;
    BookAsset? pendingReplacement;
    try {
      final action = await showBookLeatherBottomSheet<BookImageSettingsAction>(
        context: context,
        builder: (sheetContext) => BookSheetKeyboardDismiss(
          child: BookImageSettingsSheet(
            placement: placement,
            onChanged: (next) => draft = next,
            onReplace: (current) async {
              final asset = await _pickImageAsset();
              if (asset == null) return null;
              final next = current.copyWith(assetId: asset.id);
              pendingReplacement = asset;
              draft = next;
              return next;
            },
          ),
        ),
      );
      if (!mounted) return;
      switch (action ?? BookImageSettingsAction.save) {
        case BookImageSettingsAction.save:
          if (draft == placement) return;
          if (pendingReplacement != null) {
            widget.controller.addAsset(pendingReplacement!);
          }
          _updateImageInProject(offset, placement, draft);
        case BookImageSettingsAction.moveToCursor:
          if (pendingReplacement != null) {
            widget.controller.addAsset(pendingReplacement!);
          }
          _moveImageToCursor(offset, cursorOffset, placement, draft);
        case BookImageSettingsAction.delete:
          _deleteImageFromProject(offset, placement);
      }
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (editorState?.mounted ?? false) {
          editorState!.resumeTextInputFocus();
        }
      });
    }
  }

  void _updateImageInProject(
    int offset,
    BookImagePlacement current,
    BookImagePlacement next,
  ) {
    _editActiveSection((controller) {
      final actualOffset = _resolveImageOffset(
        controller,
        requestedOffset: offset,
        assetId: current.assetId,
      );
      if (actualOffset < 0 || actualOffset >= controller.document.length) {
        return false;
      }
      controller.replaceText(
        actualOffset,
        1,
        BlockEmbed.custom(CustomBlockEmbed('bookImage', next.encode())),
        null,
      );
      return true;
    });
  }

  void _deleteImageFromProject(int offset, BookImagePlacement placement) {
    _editActiveSection((controller) {
      final actualOffset = _resolveImageOffset(
        controller,
        requestedOffset: offset,
        assetId: placement.assetId,
      );
      if (actualOffset < 0 || actualOffset >= controller.document.length) {
        return false;
      }
      controller.replaceText(actualOffset, 1, '', null);
      return true;
    });
  }

  void _moveImageToCursor(
    int offset,
    int cursorOffset,
    BookImagePlacement current,
    BookImagePlacement next,
  ) {
    _editActiveSection((controller) {
      final actualOffset = _resolveImageOffset(
        controller,
        requestedOffset: offset,
        assetId: current.assetId,
      );
      if (actualOffset < 0 || actualOffset >= controller.document.length) {
        return false;
      }
      controller.replaceText(actualOffset, 1, '', null);
      final targetOffset =
          (cursorOffset > actualOffset ? cursorOffset - 1 : cursorOffset).clamp(
            0,
            controller.document.length - 1,
          );
      _insertImageAtOffset(controller, targetOffset, next);
      return true;
    });
  }

  void _editActiveSection(bool Function(QuillController controller) edit) {
    final section = widget.controller.activeSection;
    if (section == null) return;
    final controller = QuillController(
      document: Document.fromJson(section.content),
      selection: const TextSelection.collapsed(offset: 0),
    );
    final changed = edit(controller);
    if (!changed) {
      controller.dispose();
      return;
    }
    final content = controller.document
        .toDelta()
        .toJson()
        .map((operation) => Map<String, dynamic>.from(operation))
        .toList();
    controller.dispose();
    widget.controller.updateSectionContent(content);
  }

  int _resolveImageOffset(
    QuillController controller, {
    required int requestedOffset,
    required String assetId,
  }) {
    var documentOffset = 0;
    var nearestOffset = -1;
    var nearestDistance = 1 << 30;
    for (final operation in controller.document.toDelta().toJson()) {
      final insert = operation['insert'];
      if (insert is Map) {
        final data = _bookImageData(insert);
        if (data != null &&
            BookImagePlacement.decode(data).assetId == assetId) {
          if (documentOffset == requestedOffset) return documentOffset;
          final distance = (documentOffset - requestedOffset).abs();
          if (distance < nearestDistance) {
            nearestOffset = documentOffset;
            nearestDistance = distance;
          }
        }
        documentOffset++;
      } else if (insert is String) {
        documentOffset += insert.length;
      }
    }
    return nearestOffset;
  }

  String? _bookImageData(Map insert) {
    final direct = insert['bookImage']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final custom = insert['custom'];
    if (custom is! String) return null;
    try {
      final decoded = jsonDecode(custom);
      return decoded is Map ? decoded['bookImage']?.toString() : null;
    } on FormatException {
      return null;
    }
  }

  void _insertImageAtOffset(
    QuillController controller,
    int requestedOffset,
    BookImagePlacement placement,
  ) {
    final offset = requestedOffset.clamp(0, controller.document.length - 1);
    final plainText = controller.document.toPlainText();
    final startsLine = offset == 0 || plainText[offset - 1] == '\n';
    final insertion = Delta();
    if (!startsLine) insertion.insert('\n');
    insertion
      ..insert(
        BlockEmbed.custom(
          CustomBlockEmbed('bookImage', placement.encode()),
        ).toJson(),
      )
      ..insert('\n');
    controller.replaceText(offset, 0, insertion, null);
    final cursorOffset = (offset + insertion.length).clamp(
      0,
      controller.document.length - 1,
    );
    controller.updateSelection(
      TextSelection.collapsed(offset: cursorOffset),
      ChangeSource.local,
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
    await showBookLeatherBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => BookSheetKeyboardDismiss(
        child: BookExportSheet(
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
      ),
    );
  }

  Future<void> _showVersionHistory() => showBookLeatherBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => BookSheetKeyboardDismiss(
      child: FractionallySizedBox(
        heightFactor: 0.84,
        child: BookVersionHistorySheet(controller: widget.controller),
      ),
    ),
  );

  Future<void> _showSectionTrash() => showBookLeatherBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BookSheetKeyboardDismiss(
      child: FractionallySizedBox(
        heightFactor: 0.82,
        child: BookSectionTrashSheet(controller: widget.controller),
      ),
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
        builder: (context) => BookLeatherDialog(
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
    widget.controller.beginReaderSession();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BookReaderPage(
          project: project,
          readerSettings: widget.controller.readerSettings,
          onSettingsChanged:
              widget.controller.updateReaderSettingsDuringReading,
          onProgressChanged:
              widget.controller.updateReaderProgressDuringReading,
          onAnnotationsChanged:
              widget.controller.updateReaderAnnotationsDuringReading,
        ),
      ),
    );
    widget.controller.finishReaderSession();
    await widget.controller.flush();
  }
}
