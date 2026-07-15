import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_reader_annotation_exporter.dart';
import 'package:dnevnik/features/books/application/book_reader_search.dart';
import 'package:dnevnik/features/books/data/book_reader_annotation_file_service.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_annotation_export_sheet.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_navigation_panel.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_note_dialog.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_search_sheet.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_section_view.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_selection_bar.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_settings_sheet.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_text_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookReaderPage extends StatefulWidget {
  const BookReaderPage({
    required this.project,
    required this.onSettingsChanged,
    required this.onProgressChanged,
    required this.onAnnotationsChanged,
    this.annotationFileSaver = const BookReaderAnnotationFileService(),
    super.key,
  });

  final BookProject project;
  final ValueChanged<BookReaderSettings> onSettingsChanged;
  final ValueChanged<BookReaderProgress> onProgressChanged;
  final ValueChanged<BookReaderAnnotations> onAnnotationsChanged;
  final BookReaderAnnotationFileSaver annotationFileSaver;

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  late BookReaderSettings _settings;
  late BookReaderAnnotations _annotations;
  late int _activeIndex;
  double _sectionProgress = 0;
  BookReaderTextSelection? _textSelection;
  int _clearSelectionVersion = 0;

  List<BookSection> get _sections => widget.project.sections;
  BookSection get _section => _sections[_activeIndex];

  @override
  void initState() {
    super.initState();
    _settings = widget.project.readerSettings;
    _annotations = widget.project.readerAnnotations;
    final savedId = widget.project.readerProgress.sectionId;
    final savedIndex = _sections.indexWhere((section) => section.id == savedId);
    _activeIndex = savedIndex < 0 ? 0 : savedIndex;
    _sectionProgress = savedIndex < 0
        ? 0
        : widget.project.readerProgress.sectionProgress;
  }

  void _goToLocation(String sectionId, double sectionProgress) {
    _clearTextSelection();
    final index = _sections.indexWhere((section) => section.id == sectionId);
    if (index < 0) return;
    final normalizedProgress = sectionProgress.clamp(0, 1).toDouble();
    if (index == _activeIndex) {
      setState(() => _sectionProgress = normalizedProgress);
      _saveProgress();
      return;
    }
    _saveProgress();
    setState(() {
      _activeIndex = index;
      _sectionProgress = normalizedProgress;
    });
    _saveProgress();
  }

  void _saveProgress() => widget.onProgressChanged(
    BookReaderProgress(
      sectionId: _section.id,
      sectionProgress: _sectionProgress,
    ),
  );

  void _handleSectionProgress(double progress) {
    final normalized = progress.clamp(0, 1).toDouble();
    if ((normalized - _sectionProgress).abs() < 0.001) return;
    setState(() => _sectionProgress = normalized);
    _saveProgress();
  }

  double get _overallProgress {
    if (_sections.isEmpty) return 0;
    return ((_activeIndex + _sectionProgress) / _sections.length).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final palette = BookReaderPalette.forTheme(_settings.theme);
    return Theme(
      data: palette.themeData(Theme.of(context)),
      child: Builder(
        builder: (context) => LayoutBuilder(
          builder: (context, constraints) {
            final showContents = constraints.maxWidth >= 1050;
            return PopScope(
              onPopInvokedWithResult: (_, _) => _saveProgress(),
              child: Scaffold(
                appBar: _buildAppBar(context, showContents),
                body: Column(
                  children: [
                    LinearProgressIndicator(
                      key: const ValueKey('reader-progress'),
                      value: _overallProgress,
                      minHeight: 3,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          if (showContents)
                            SizedBox(
                              width: 300,
                              child: Material(
                                color: palette.surface,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _navigationPanel(
                                        context,
                                        closeAfterSelection: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Expanded(
                            child: _buildReadingSurface(context, palette),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: _buildNavigationBar(context, palette),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool showContents) {
    final strings = AppStrings.of(context);
    return AppBar(
      titleSpacing: 12,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.project.metadata.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _section.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        IconButton(
          key: const ValueKey('reader-search-button'),
          tooltip: strings.searchInBook,
          onPressed: () => _showSearch(context),
          icon: const Icon(Icons.search),
        ),
        if (!showContents)
          IconButton(
            key: const ValueKey('reader-contents-button'),
            tooltip: strings.tableOfContents,
            onPressed: () => _showContents(context),
            icon: const Icon(Icons.toc),
          ),
        IconButton(
          key: const ValueKey('reader-bookmark-button'),
          tooltip: _currentBookmark == null
              ? strings.addBookmark
              : strings.removeBookmark,
          onPressed: _toggleBookmark,
          icon: Icon(
            _currentBookmark == null ? Icons.bookmark_border : Icons.bookmark,
          ),
        ),
        IconButton(
          key: const ValueKey('reader-settings-button'),
          tooltip: strings.readingSettings,
          onPressed: () => _showSettings(context),
          icon: const Icon(Icons.text_fields),
        ),
      ],
    );
  }

  Widget _buildReadingSurface(
    BuildContext context,
    BookReaderPalette palette,
  ) => Stack(
    children: [
      Positioned.fill(
        child: BookReaderSectionView(
          section: _section,
          settings: _settings,
          palette: palette,
          initialProgress: _sectionProgress,
          onProgressChanged: _handleSectionProgress,
          highlights: _annotations.highlights
              .where((highlight) => highlight.sectionId == _section.id)
              .toList(),
          onTextSelection: _handleTextSelection,
          clearSelectionVersion: _clearSelectionVersion,
        ),
      ),
      if (_textSelection case final selection?)
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Center(
            child: BookReaderSelectionBar(
              selection: selection,
              onHighlight: _saveHighlight,
              onSaveQuote: _saveQuote,
              onAddNote: () => _addNoteForSelection(context),
              onCopy: _copySelection,
              onClose: _clearTextSelection,
            ),
          ),
        ),
    ],
  );

  Widget _buildNavigationBar(BuildContext context, BookReaderPalette palette) {
    final strings = AppStrings.of(context);
    final percent = (_overallProgress * 100).round();
    return Material(
      color: palette.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('reader-previous-section'),
                tooltip: strings.previousSection,
                onPressed: _activeIndex > 0
                    ? () => _goToIndex(_activeIndex - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Semantics(
                  label: strings.readingProgress,
                  child: Text(
                    '${strings.sectionOf(_activeIndex + 1, _sections.length)} · $percent%',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.mutedInk),
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('reader-next-section'),
                tooltip: strings.nextSection,
                onPressed: _activeIndex < _sections.length - 1
                    ? () => _goToIndex(_activeIndex + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BookReaderBookmark? get _currentBookmark => _annotations.bookmarks
      .where(
        (bookmark) =>
            bookmark.sectionId == _section.id &&
            (bookmark.sectionProgress - _sectionProgress).abs() < 0.02,
      )
      .firstOrNull;

  Widget _navigationPanel(
    BuildContext panelContext, {
    required bool closeAfterSelection,
  }) => BookReaderNavigationPanel(
    sections: _sections,
    activeSectionId: _section.id,
    annotations: _annotations,
    onLocationSelected: (sectionId, progress) {
      _goToLocation(sectionId, progress);
      if (closeAfterSelection) Navigator.of(panelContext).pop();
    },
    onAddNote: () => _addNote(panelContext),
    onEditNote: (note) => _editNote(panelContext, note),
    onDeleteBookmark: (bookmark) =>
        _updateAnnotations(_annotations.removeBookmark(bookmark.id)),
    onDeleteNote: (note) =>
        _updateAnnotations(_annotations.removeNote(note.id)),
    onHighlightColorChanged: (highlight, color) => _updateAnnotations(
      _annotations.updateHighlight(highlight.copyWith(color: color)),
    ),
    onDeleteHighlight: (highlight) =>
        _updateAnnotations(_annotations.removeHighlight(highlight.id)),
    onDeleteQuote: (quote) =>
        _updateAnnotations(_annotations.removeQuote(quote.id)),
    onExport: () => _showAnnotationExport(panelContext),
  );

  void _goToIndex(int index) => _goToLocation(_sections[index].id, 0);

  Future<void> _showContents(BuildContext themedContext) =>
      showModalBottomSheet<void>(
        context: themedContext,
        isScrollControlled: true,
        builder: (sheetContext) => FractionallySizedBox(
          heightFactor: 0.82,
          child: _navigationPanel(sheetContext, closeAfterSelection: true),
        ),
      );

  Future<void> _showSearch(BuildContext themedContext) =>
      showModalBottomSheet<void>(
        context: themedContext,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => FractionallySizedBox(
          heightFactor: 0.88,
          child: BookReaderSearchSheet(
            sections: _sections,
            onSelected: (result) {
              Navigator.of(sheetContext).pop();
              _goToSearchResult(result);
            },
          ),
        ),
      );

  Future<void> _showSettings(BuildContext themedContext) =>
      showModalBottomSheet<void>(
        context: themedContext,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => BookReaderSettingsSheet(
          settings: _settings,
          onChanged: (settings) {
            setState(() => _settings = settings);
            widget.onSettingsChanged(settings);
          },
        ),
      );

  void _goToSearchResult(BookReaderSearchResult result) =>
      _goToLocation(result.sectionId, result.sectionProgress);

  void _toggleBookmark() {
    final current = _currentBookmark;
    if (current != null) {
      _updateAnnotations(_annotations.removeBookmark(current.id));
      return;
    }
    _updateAnnotations(
      _annotations.addBookmark(
        BookReaderBookmark.create(
          sectionId: _section.id,
          sectionProgress: _sectionProgress,
          excerpt: _currentExcerpt(),
        ),
      ),
    );
  }

  void _updateAnnotations(BookReaderAnnotations annotations) {
    setState(() => _annotations = annotations);
    widget.onAnnotationsChanged(annotations);
  }

  void _handleTextSelection(BookReaderTextSelection? selection) {
    if (!mounted || selection == null && _textSelection == null) return;
    setState(() => _textSelection = selection);
  }

  void _clearTextSelection() {
    if (_textSelection == null) return;
    setState(() {
      _textSelection = null;
      _clearSelectionVersion++;
    });
  }

  void _saveHighlight(BookReaderHighlightColor color) {
    final selection = _textSelection;
    if (selection == null) return;
    _updateAnnotations(
      _annotations.addHighlight(
        BookReaderHighlight.create(
          sectionId: _section.id,
          sectionProgress: selection.sectionProgress,
          startOffset: selection.startOffset,
          endOffset: selection.endOffset,
          excerpt: selection.text,
          color: color,
        ),
      ),
    );
    _showMessage(AppStrings.of(context).highlightSaved);
    _clearTextSelection();
  }

  void _saveQuote() {
    final selection = _textSelection;
    if (selection == null) return;
    _updateAnnotations(
      _annotations.addQuote(
        BookReaderQuote.create(
          sectionId: _section.id,
          sectionProgress: selection.sectionProgress,
          startOffset: selection.startOffset,
          endOffset: selection.endOffset,
          text: selection.text,
        ),
      ),
    );
    _showMessage(AppStrings.of(context).quoteSaved);
    _clearTextSelection();
  }

  Future<void> _copySelection() async {
    final selection = _textSelection;
    if (selection == null) return;
    await Clipboard.setData(ClipboardData(text: selection.text));
    if (!mounted) return;
    _showMessage(AppStrings.of(context).selectionCopied);
    _clearTextSelection();
  }

  Future<void> _addNoteForSelection(BuildContext themedContext) async {
    final selection = _textSelection;
    if (selection == null) return;
    final text = await _showNoteEditor(themedContext);
    if (text == null || !mounted) return;
    _updateAnnotations(
      _annotations.addNote(
        BookReaderNote.create(
          sectionId: _section.id,
          sectionProgress: selection.sectionProgress,
          excerpt: selection.text,
          text: text,
        ),
      ),
    );
    _clearTextSelection();
  }

  Future<void> _showAnnotationExport(BuildContext themedContext) =>
      showModalBottomSheet<void>(
        context: themedContext,
        showDragHandle: true,
        builder: (sheetContext) => BookReaderAnnotationExportSheet(
          onSelected: (format) {
            Navigator.of(sheetContext).pop();
            _exportAnnotations(themedContext, format);
          },
        ),
      );

  Future<void> _exportAnnotations(
    BuildContext themedContext,
    BookReaderAnnotationExportFormat format,
  ) async {
    final strings = AppStrings.of(themedContext);
    try {
      final export = BookReaderAnnotationExporter.create(
        project: widget.project.copyWith(readerAnnotations: _annotations),
        format: format,
        languageCode: Localizations.localeOf(themedContext).languageCode,
      );
      final saved = await widget.annotationFileSaver.save(
        export: export,
        bookTitle: widget.project.metadata.title,
      );
      if (!mounted || !saved) return;
      _showMessage(strings.annotationsExported);
    } on Exception {
      if (mounted) _showMessage(strings.annotationsExportFailed);
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1400),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _currentExcerpt() {
    final text = richDocumentPlainText(
      _section.content,
    ).replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return _section.title;
    const length = 72;
    final center = (text.length * _sectionProgress).round();
    final start = (center - length ~/ 2).clamp(0, text.length);
    final end = (start + length).clamp(0, text.length);
    return '${start > 0 ? '…' : ''}${text.substring(start, end)}${end < text.length ? '…' : ''}';
  }

  Future<void> _addNote(BuildContext themedContext) async {
    final text = await _showNoteEditor(themedContext);
    if (text == null) return;
    _updateAnnotations(
      _annotations.addNote(
        BookReaderNote.create(
          sectionId: _section.id,
          sectionProgress: _sectionProgress,
          excerpt: _currentExcerpt(),
          text: text,
        ),
      ),
    );
  }

  Future<void> _editNote(
    BuildContext themedContext,
    BookReaderNote note,
  ) async {
    final text = await _showNoteEditor(themedContext, note: note);
    if (text == null) return;
    _updateAnnotations(
      _annotations.updateNote(
        note.copyWith(text: text, updatedAt: DateTime.now()),
      ),
    );
  }

  Future<String?> _showNoteEditor(
    BuildContext themedContext, {
    BookReaderNote? note,
  }) => showDialog<String>(
    context: themedContext,
    builder: (_) => BookReaderNoteDialog(initialText: note?.text ?? ''),
  );
}
