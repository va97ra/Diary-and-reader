import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_epub_exporter.dart';
import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/data/book_export_file_service.dart';
import 'package:dnevnik/features/books/presentation/book_export_sheet.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_formatting_toolbar.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_navigator.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_properties_panel.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_section_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class AuthorWorkspacePage extends StatefulWidget {
  const AuthorWorkspacePage({
    required this.controller,
    this.exportFileSaver = const BookExportFileService(),
    super.key,
  });

  final AuthorWorkspaceController controller;
  final BookExportFileSaver exportFileSaver;

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
      builder: (sheetContext) => BookExportSheet(
        onSelected: (format) {
          Navigator.of(sheetContext).pop();
          _exportBook(format);
        },
      ),
    );
  }

  Future<void> _exportBook(BookExportFormat format) async {
    final strings = AppStrings.of(context);
    final project = widget.controller.activeProject;
    if (project == null) return;
    try {
      final artifact = switch (format) {
        BookExportFormat.epub => BookEpubExporter.create(project),
      };
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
