import 'dart:async';

import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_contents.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_settings_sheet.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookReaderPage extends StatefulWidget {
  const BookReaderPage({
    required this.project,
    required this.onSettingsChanged,
    required this.onProgressChanged,
    super.key,
  });

  final BookProject project;
  final ValueChanged<BookReaderSettings> onSettingsChanged;
  final ValueChanged<BookReaderProgress> onProgressChanged;

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  late BookReaderSettings _settings;
  late int _activeIndex;
  late QuillController _controller;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  Timer? _progressTimer;
  double _sectionProgress = 0;

  List<BookSection> get _sections => widget.project.sections;
  BookSection get _section => _sections[_activeIndex];

  @override
  void initState() {
    super.initState();
    _settings = widget.project.readerSettings;
    final savedId = widget.project.readerProgress.sectionId;
    final savedIndex = _sections.indexWhere((section) => section.id == savedId);
    _activeIndex = savedIndex < 0 ? 0 : savedIndex;
    _sectionProgress = savedIndex < 0
        ? 0
        : widget.project.readerProgress.sectionProgress;
    _createDocumentController();
    _restoreScrollPosition();
  }

  void _createDocumentController() {
    _controller = QuillController(
      document: Document.fromJson(_section.content),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    _focusNode = FocusNode(canRequestFocus: false);
    _scrollController = ScrollController()..addListener(_scheduleProgressSave);
  }

  void _replaceDocumentController() {
    final oldController = _controller;
    final oldFocusNode = _focusNode;
    final oldScrollController = _scrollController;
    _createDocumentController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController.dispose();
      oldFocusNode.dispose();
      oldScrollController.dispose();
    });
  }

  void _selectSection(BookSection selected) {
    final index = _sections.indexWhere((section) => section.id == selected.id);
    if (index < 0 || index == _activeIndex) return;
    _saveProgress();
    setState(() {
      _activeIndex = index;
      _sectionProgress = 0;
      _replaceDocumentController();
    });
    _saveProgress();
  }

  void _scheduleProgressSave() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final next = max <= 0
        ? 0.0
        : (_scrollController.offset / max).clamp(0, 1).toDouble();
    if ((next - _sectionProgress).abs() < 0.005) return;
    setState(() => _sectionProgress = next);
    _progressTimer?.cancel();
    _progressTimer = Timer(const Duration(milliseconds: 450), _saveProgress);
  }

  void _saveProgress() => widget.onProgressChanged(
    BookReaderProgress(
      sectionId: _section.id,
      sectionProgress: _sectionProgress,
    ),
  );

  void _restoreScrollPosition() {
    if (_sectionProgress <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        if (!mounted || !_scrollController.hasClients) return;
        _scrollController.jumpTo(
          _sectionProgress * _scrollController.position.maxScrollExtent,
        );
      });
    });
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
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        18,
                                        20,
                                        8,
                                      ),
                                      child: Text(
                                        AppStrings.of(context).tableOfContents,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    Expanded(
                                      child: _contents(
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
        if (!showContents)
          IconButton(
            key: const ValueKey('reader-contents-button'),
            tooltip: strings.tableOfContents,
            onPressed: () => _showContents(context),
            icon: const Icon(Icons.toc),
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
  ) => ColoredBox(
    color: palette.background,
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _settings.contentWidth + 96),
        child: Container(
          key: const ValueKey('reader-surface'),
          width: double.infinity,
          color: palette.surface,
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _section.title,
                style: TextStyle(
                  color: palette.ink,
                  fontFamily: _settings.fontFamily,
                  fontSize: _settings.fontSize * 1.75,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Divider(color: palette.divider, height: 1),
              const SizedBox(height: 18),
              Expanded(
                child: QuillEditor(
                  key: ValueKey('reader-document-${_section.id}'),
                  controller: _controller,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  config: QuillEditorConfig(
                    padding: EdgeInsets.zero,
                    customStyles: BookReaderTypography.styles(
                      _settings,
                      palette,
                    ),
                    scrollable: true,
                    autoFocus: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
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

  Widget _contents({required bool closeAfterSelection}) => BookReaderContents(
    sections: _sections,
    activeSectionId: _section.id,
    onSelected: (section) {
      _selectSection(section);
      if (closeAfterSelection) Navigator.of(context).pop();
    },
  );

  void _goToIndex(int index) => _selectSection(_sections[index]);

  Future<void> _showContents(BuildContext themedContext) =>
      showModalBottomSheet<void>(
        context: themedContext,
        isScrollControlled: true,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.82,
          child: _contents(closeAfterSelection: true),
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

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
