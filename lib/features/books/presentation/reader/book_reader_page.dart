import 'dart:async';

import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_reader_annotation_exporter.dart';
import 'package:dnevnik/features/books/application/book_reader_external_lookup.dart';
import 'package:dnevnik/features/books/application/book_reader_search.dart';
import 'package:dnevnik/features/books/application/book_speech_engine.dart';
import 'package:dnevnik/features/books/data/book_reader_annotation_file_service.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_reading_progress.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_annotation_export_sheet.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_context_bar.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_navigation_panel.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_note_dialog.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_progress_rail.dart';
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
    required this.readerSettings,
    required this.onSettingsChanged,
    required this.onProgressChanged,
    required this.onAnnotationsChanged,
    this.onReadingTimeChanged,
    this.uriLauncher = launchBookReaderUri,
    this.speechEngine,
    this.annotationFileSaver = const BookReaderAnnotationFileService(),
    super.key,
  });

  final BookProject project;
  final BookReaderSettings readerSettings;
  final ValueChanged<BookReaderSettings> onSettingsChanged;
  final ValueChanged<BookReaderProgress> onProgressChanged;
  final ValueChanged<BookReaderAnnotations> onAnnotationsChanged;
  final ValueChanged<Duration>? onReadingTimeChanged;
  final BookReaderUriLauncher uriLauncher;
  final BookSpeechEngine? speechEngine;
  final BookReaderAnnotationFileSaver annotationFileSaver;

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  final Stopwatch _readingStopwatch = Stopwatch();
  late final BookSpeechEngine _speechEngine;
  late BookReaderSettings _settings;
  late BookReaderAnnotations _annotations;
  late int _activeIndex;
  double _sectionProgress = 0;
  BookReaderTextSelection? _textSelection;
  int _clearSelectionVersion = 0;
  bool _isFocusMode = false;
  bool _isSpeaking = false;
  List<String> _speechChunks = const [];
  int _speechChunkIndex = 0;

  List<BookSection> get _sections => widget.project.sections;
  BookSection get _section => _sections[_activeIndex];

  @override
  void initState() {
    super.initState();
    _settings = widget.readerSettings;
    _speechEngine = widget.speechEngine ?? FlutterBookSpeechEngine();
    _speechEngine.setCompletionHandler(
      () => unawaited(_handleSpeechCompleted()),
    );
    _readingStopwatch.start();
    _annotations = widget.project.readerAnnotations;
    final savedId = widget.project.readerProgress.sectionId;
    final savedIndex = _sections.indexWhere((section) => section.id == savedId);
    _activeIndex = savedIndex < 0 ? 0 : savedIndex;
    _sectionProgress = savedIndex < 0
        ? 0
        : widget.project.readerProgress.sectionProgress;
  }

  @override
  void dispose() {
    _readingStopwatch.stop();
    unawaited(_speechEngine.stop());
    widget.onReadingTimeChanged?.call(_readingStopwatch.elapsed);
    super.dispose();
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
    return bookReadingProgress(
      _sections,
      BookReaderProgress(
        sectionId: _section.id,
        sectionProgress: _sectionProgress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = BookReaderPalette.forTheme(_settings.theme);
    return Theme(
      data: palette.themeData(Theme.of(context)),
      child: Builder(
        builder: (context) => LayoutBuilder(
          builder: (context, _) {
            return PopScope(
              canPop: !_isFocusMode,
              onPopInvokedWithResult: (didPop, _) {
                _saveProgress();
                if (!didPop && _isFocusMode) {
                  setState(() => _isFocusMode = false);
                }
              },
              child: Scaffold(
                appBar: _isFocusMode ? null : _buildAppBar(context),
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildReadingSurface(context, palette),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: BookReaderProgressRail(
                        value: _overallProgress,
                        trackColor: palette.mutedInk.withValues(alpha: 0.22),
                        progressColor: Theme.of(context).colorScheme.primary,
                        semanticLabel: AppStrings.of(context).readingProgress,
                      ),
                    ),
                    if (_isFocusMode)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: SafeArea(
                          child: Material(
                            color: palette.surface.withValues(alpha: 0.84),
                            elevation: 2,
                            shape: const CircleBorder(),
                            child: IconButton(
                              key: const ValueKey('reader-exit-focus-mode'),
                              tooltip: AppStrings.of(context).exitFocusReading,
                              visualDensity: VisualDensity.compact,
                              onPressed: _toggleFocusMode,
                              icon: const Icon(Icons.fullscreen_exit),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                bottomNavigationBar: _isFocusMode
                    ? null
                    : _buildNavigationBar(context, palette),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
          key: const ValueKey('reader-tts-action'),
          tooltip: _isSpeaking
              ? strings.stopReadingAloud
              : strings.startReadingAloud,
          onPressed: _toggleSpeech,
          icon: Icon(_isSpeaking ? Icons.stop_circle : Icons.volume_up),
        ),
        IconButton(
          key: const ValueKey('reader-hide-panels-button'),
          tooltip: strings.focusReading,
          onPressed: _toggleFocusMode,
          icon: const Icon(Icons.fullscreen),
        ),
        PopupMenuButton<_ReaderMoreAction>(
          key: const ValueKey('reader-more-menu'),
          tooltip: strings.more,
          onSelected: (action) {
            if (action == _ReaderMoreAction.search) _showSearch(context);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: _ReaderMoreAction.search,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.search),
                title: Text(strings.searchInBook),
              ),
            ),
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Center(child: Text(strings.more)),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _toggleFocusMode() {
    _clearTextSelection();
    setState(() => _isFocusMode = !_isFocusMode);
  }

  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      setState(() => _isSpeaking = false);
      _speechChunks = const [];
      _speechChunkIndex = 0;
      await _speechEngine.stop();
      return;
    }
    await _configureSpeechForSection();
    _prepareSpeechChunks(useCurrentProgress: true);
    if (_speechChunks.isEmpty) return;
    setState(() => _isSpeaking = true);
    await _speakNextChunk();
  }

  Future<void> _configureSpeechForSection() => _speechEngine.configure(
    languageCode: widget.project.metadata.languageCode,
    rate: _settings.speechRate,
    pitch: _settings.speechPitch,
    bookTitle: widget.project.metadata.title,
    chapterTitle: _section.title,
  );

  void _prepareSpeechChunks({required bool useCurrentProgress}) {
    final text = richDocumentPlainText(_section.content).trim();
    final offset = useCurrentProgress
        ? (text.length * _sectionProgress).round().clamp(0, text.length)
        : 0;
    _speechChunks = _splitSpeech(text.substring(offset));
    _speechChunkIndex = 0;
  }

  List<String> _splitSpeech(String text) {
    const limit = 3500;
    final chunks = <String>[];
    var remaining = text.trim();
    while (remaining.isNotEmpty) {
      if (remaining.length <= limit) {
        chunks.add(remaining);
        break;
      }
      var split = remaining.lastIndexOf(RegExp(r'[.!?\n ]'), limit);
      if (split < limit ~/ 2) split = limit;
      chunks.add(remaining.substring(0, split).trim());
      remaining = remaining.substring(split).trimLeft();
    }
    return chunks.where((chunk) => chunk.isNotEmpty).toList();
  }

  Future<void> _speakNextChunk() async {
    if (!_isSpeaking || _speechChunkIndex >= _speechChunks.length) return;
    await _speechEngine.speak(_speechChunks[_speechChunkIndex++]);
  }

  Future<void> _handleSpeechCompleted() async {
    if (!_isSpeaking || !mounted) return;
    if (_speechChunkIndex < _speechChunks.length) {
      await _speakNextChunk();
      return;
    }
    if (_activeIndex < _sections.length - 1) {
      _goToNextSection();
      await _configureSpeechForSection();
      _prepareSpeechChunks(useCurrentProgress: false);
      await _speakNextChunk();
      return;
    }
    setState(() => _isSpeaking = false);
  }

  Widget _buildReadingSurface(
    BuildContext context,
    BookReaderPalette palette,
  ) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTapUp: _settings.centerTapControls
        ? (details) => _handleReadingSurfaceTap(context, details)
        : null,
    child: Stack(
      children: [
        Positioned.fill(
          child: BookReaderSectionView(
            section: _section,
            languageCode: widget.project.metadata.languageCode,
            assets: widget.project.assets,
            settings: _settings,
            palette: palette,
            initialProgress: _sectionProgress,
            onProgressChanged: _handleSectionProgress,
            highlights: _annotations.highlights
                .where((highlight) => highlight.sectionId == _section.id)
                .toList(),
            onTextSelection: _handleTextSelection,
            clearSelectionVersion: _clearSelectionVersion,
            onNextSectionRequested: _activeIndex < _sections.length - 1
                ? _goToNextSection
                : null,
            onPreviousSectionRequested: _activeIndex > 0
                ? _goToPreviousSectionEnd
                : null,
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
                onDictionary: () =>
                    _openSelectionLookup(BookReaderLookupAction.dictionary),
                onTranslate: () =>
                    _openSelectionLookup(BookReaderLookupAction.translate),
                onWebSearch: () =>
                    _openSelectionLookup(BookReaderLookupAction.webSearch),
                onClose: _clearTextSelection,
              ),
            ),
          ),
      ],
    ),
  );

  void _handleReadingSurfaceTap(BuildContext context, TapUpDetails details) {
    if (_textSelection != null) return;
    final width = context.size?.width ?? MediaQuery.sizeOf(context).width;
    final position = details.localPosition.dx / width;
    if (position >= 0.32 && position <= 0.68) _toggleFocusMode();
  }

  Widget _buildNavigationBar(BuildContext context, BookReaderPalette palette) {
    return BookReaderContextBar(
      palette: palette,
      canGoPrevious: _activeIndex > 0,
      canGoNext: _activeIndex < _sections.length - 1,
      isBookmarked: _currentBookmark != null,
      onPrevious: () => _goToIndex(_activeIndex - 1),
      onContents: () => _showContents(context),
      onSettings: () => _showSettings(context),
      onBookmark: _toggleBookmark,
      onNext: () => _goToIndex(_activeIndex + 1),
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

  void _goToNextSection() {
    if (_activeIndex >= _sections.length - 1) return;
    _sectionProgress = 1;
    _saveProgress();
    _goToLocation(_sections[_activeIndex + 1].id, 0);
  }

  void _goToPreviousSectionEnd() {
    if (_activeIndex <= 0) return;
    _goToLocation(_sections[_activeIndex - 1].id, 1);
  }

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

  Future<void> _openSelectionLookup(BookReaderLookupAction action) async {
    final selection = _textSelection;
    if (selection == null) return;
    final uri = BookReaderExternalLookup.uri(
      action: action,
      text: selection.text,
      languageCode: widget.project.metadata.languageCode,
    );
    try {
      final opened = await widget.uriLauncher(uri);
      if (!opened && mounted) {
        _showMessage(AppStrings.of(context).externalActionFailed);
      }
    } on Exception {
      if (mounted) _showMessage(AppStrings.of(context).externalActionFailed);
    }
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

enum _ReaderMoreAction { search }
