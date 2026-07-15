import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_page_paginator.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page_card.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookReaderSectionView extends StatefulWidget {
  const BookReaderSectionView({
    required this.section,
    required this.settings,
    required this.palette,
    required this.initialProgress,
    required this.onProgressChanged,
    super.key,
  });

  final BookSection section;
  final BookReaderSettings settings;
  final BookReaderPalette palette;
  final double initialProgress;
  final ValueChanged<double> onProgressChanged;

  @override
  State<BookReaderSectionView> createState() => _BookReaderSectionViewState();
}

class _BookReaderSectionViewState extends State<BookReaderSectionView> {
  late QuillController _continuousController;
  late FocusNode _continuousFocusNode;
  late ScrollController _continuousScrollController;

  final _pageControllers = <QuillController>[];
  final _pageFocusNodes = <FocusNode>[];
  final _pageScrollControllers = <ScrollController>[];
  final _pageEditorKeys = <GlobalKey<EditorState>>[];
  final _pageViewportKeys = <GlobalKey>[];
  List<RichDocument> _pageDocuments = const [];
  List<int> _pageStartOffsets = const [];

  Timer? _progressTimer;
  Timer? _paginationTimer;
  double _progress = 0;
  double _pendingProgress = 0;
  int _activePage = 0;
  int _paginationRequest = 0;
  int _measurementRetries = 0;
  bool _isPaginating = false;
  _ReaderPageGeometry? _geometry;
  _ReaderPageGeometry? _completedGeometry;
  BookReaderViewMode _effectiveMode = BookReaderViewMode.continuous;

  final _measuredPages = <RichDocument>[];
  RichDocument? _measurementDocument;
  QuillController? _measurementController;
  FocusNode? _measurementFocusNode;
  ScrollController? _measurementScrollController;
  GlobalKey<EditorState>? _measurementEditorKey;
  GlobalKey? _measurementViewportKey;

  @override
  void initState() {
    super.initState();
    _progress = widget.initialProgress.clamp(0, 1).toDouble();
    _pendingProgress = _progress;
    _createContinuousResources();
    _restoreContinuousPosition();
  }

  void _createContinuousResources() {
    _continuousController = QuillController(
      document: Document.fromJson(widget.section.content),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    _continuousFocusNode = FocusNode(canRequestFocus: false);
    _continuousScrollController = ScrollController()
      ..addListener(_handleContinuousScroll);
  }

  @override
  void didUpdateWidget(covariant BookReaderSectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sectionChanged =
        oldWidget.section.id != widget.section.id ||
        jsonEncode(oldWidget.section.content) !=
            jsonEncode(widget.section.content);
    if (sectionChanged) {
      _replaceContinuousResources();
      _clearVisiblePages();
      _invalidatePagination();
    } else if (_layoutSettingsChanged(oldWidget.settings, widget.settings)) {
      _invalidatePagination();
    }

    if ((widget.initialProgress - _progress).abs() > 0.004 || sectionChanged) {
      _progress = widget.initialProgress.clamp(0, 1).toDouble();
      _pendingProgress = _progress;
      _restoreCurrentPosition();
    } else if (oldWidget.settings != widget.settings) {
      _restoreCurrentPosition();
    }
  }

  bool _layoutSettingsChanged(
    BookReaderSettings oldSettings,
    BookReaderSettings newSettings,
  ) =>
      oldSettings.fontFamily != newSettings.fontFamily ||
      oldSettings.fontSize != newSettings.fontSize ||
      oldSettings.lineHeight != newSettings.lineHeight ||
      oldSettings.contentWidth != newSettings.contentWidth ||
      oldSettings.horizontalPadding != newSettings.horizontalPadding ||
      oldSettings.verticalPadding != newSettings.verticalPadding;

  void _replaceContinuousResources() {
    final oldController = _continuousController;
    final oldFocusNode = _continuousFocusNode;
    final oldScrollController = _continuousScrollController;
    _createContinuousResources();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController.dispose();
      oldFocusNode.dispose();
      oldScrollController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mode = _modeForWidth(constraints.maxWidth);
      if (_effectiveMode != mode) {
        _effectiveMode = mode;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _restoreCurrentPosition(),
        );
      }
      if (mode == BookReaderViewMode.continuous) {
        return _buildContinuousView();
      }
      final geometry = _ReaderPageGeometry.fromConstraints(
        constraints,
        settings: widget.settings,
        spread: mode == BookReaderViewMode.spread,
      );
      if (_geometry != geometry) {
        _geometry = geometry;
        _schedulePagination();
      }
      return _buildPagedView(context, geometry, mode);
    },
  );

  BookReaderViewMode _modeForWidth(double width) {
    if (widget.settings.viewMode == BookReaderViewMode.spread && width < 700) {
      return BookReaderViewMode.singlePage;
    }
    return widget.settings.viewMode;
  }

  Widget _buildContinuousView() => ColoredBox(
    key: const ValueKey('reader-continuous-view'),
    color: widget.palette.background,
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              widget.settings.contentWidth +
              widget.settings.horizontalPadding * 2,
        ),
        child: Container(
          key: const ValueKey('reader-surface'),
          width: double.infinity,
          color: widget.palette.surface,
          padding: EdgeInsets.fromLTRB(
            widget.settings.horizontalPadding,
            widget.settings.verticalPadding,
            widget.settings.horizontalPadding,
            8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.section.title,
                style: TextStyle(
                  color: widget.palette.ink,
                  fontFamily: widget.settings.fontFamily,
                  fontSize: widget.settings.fontSize * 1.75,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Divider(color: widget.palette.divider, height: 1),
              const SizedBox(height: 18),
              Expanded(
                child: QuillEditor(
                  key: ValueKey('reader-document-${widget.section.id}'),
                  controller: _continuousController,
                  focusNode: _continuousFocusNode,
                  scrollController: _continuousScrollController,
                  config: QuillEditorConfig(
                    padding: EdgeInsets.zero,
                    customStyles: BookReaderTypography.styles(
                      widget.settings,
                      widget.palette,
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

  Widget _buildPagedView(
    BuildContext context,
    _ReaderPageGeometry geometry,
    BookReaderViewMode mode,
  ) {
    final pagesMatchGeometry =
        _pageControllers.isNotEmpty && _completedGeometry == geometry;
    return ColoredBox(
      key: ValueKey(
        mode == BookReaderViewMode.spread
            ? 'reader-spread-view'
            : 'reader-single-page-view',
      ),
      color: widget.palette.background,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: pagesMatchGeometry
                ? _buildPageStage(context, geometry, mode)
                : const Center(
                    key: ValueKey('reader-page-loading'),
                    child: CircularProgressIndicator(),
                  ),
          ),
          if (_isPaginating && pagesMatchGeometry)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          if (_measurementController != null)
            Positioned(
              left: -geometry.width * 2,
              top: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0,
                  child: BookReaderPageCard(
                    width: geometry.width,
                    height: geometry.height,
                    sectionTitle: widget.section.title,
                    pageNumber: 1,
                    pageCount: 1,
                    settings: widget.settings,
                    palette: widget.palette,
                    controller: _measurementController!,
                    focusNode: _measurementFocusNode!,
                    scrollController: _measurementScrollController!,
                    editorKey: _measurementEditorKey!,
                    viewportKey: _measurementViewportKey!,
                    isMeasurement: true,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageStage(
    BuildContext context,
    _ReaderPageGeometry geometry,
    BookReaderViewMode mode,
  ) {
    final isSpread = mode == BookReaderViewMode.spread;
    final firstPage = isSpread ? (_activePage ~/ 2) * 2 : _activePage;
    final indices = [
      firstPage,
      if (isSpread && firstPage + 1 < _pageControllers.length) firstPage + 1,
    ];
    final previous = firstPage > 0 ? firstPage - (isSpread ? 2 : 1) : null;
    final next = firstPage + (isSpread ? 2 : 1) < _pageControllers.length
        ? firstPage + (isSpread ? 2 : 1)
        : null;
    final strings = AppStrings.of(context);

    return Stack(
      children: [
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < indices.length; index++) ...[
                if (index > 0) const SizedBox(width: 16),
                _buildPage(indices[index], geometry),
              ],
            ],
          ),
        ),
        Positioned(
          left: 6,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton.filledTonal(
              key: const ValueKey('reader-previous-page'),
              tooltip: strings.previousReaderPage,
              onPressed: previous == null ? null : () => _selectPage(previous),
              icon: const Icon(Icons.chevron_left),
            ),
          ),
        ),
        Positioned(
          right: 6,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton.filledTonal(
              key: const ValueKey('reader-next-page'),
              tooltip: strings.nextReaderPage,
              onPressed: next == null ? null : () => _selectPage(next),
              icon: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage(int index, _ReaderPageGeometry geometry) =>
      BookReaderPageCard(
        width: geometry.width,
        height: geometry.height,
        sectionTitle: widget.section.title,
        pageNumber: index + 1,
        pageCount: _pageControllers.length,
        settings: widget.settings,
        palette: widget.palette,
        controller: _pageControllers[index],
        focusNode: _pageFocusNodes[index],
        scrollController: _pageScrollControllers[index],
        editorKey: _pageEditorKeys[index],
        viewportKey: _pageViewportKeys[index],
      );

  void _handleContinuousScroll() {
    if (!_continuousScrollController.hasClients ||
        _effectiveMode != BookReaderViewMode.continuous) {
      return;
    }
    final max = _continuousScrollController.position.maxScrollExtent;
    final next = max <= 0
        ? 0.0
        : (_continuousScrollController.offset / max).clamp(0, 1).toDouble();
    if ((next - _progress).abs() < 0.004) return;
    _progress = next;
    _pendingProgress = next;
    _progressTimer?.cancel();
    _progressTimer = Timer(
      const Duration(milliseconds: 350),
      () => widget.onProgressChanged(_progress),
    );
  }

  void _selectPage(int page) {
    if (page < 0 || page >= _pageControllers.length || page == _activePage) {
      return;
    }
    setState(() => _activePage = page);
    final totalLength = _documentContentLength(widget.section.content);
    final offset = _pageStartOffsets[page];
    _progress = totalLength <= 0 ? 0 : (offset / totalLength).clamp(0, 1);
    _pendingProgress = _progress;
    widget.onProgressChanged(_progress);
  }

  void _restoreCurrentPosition() {
    if (_effectiveMode == BookReaderViewMode.continuous) {
      _restoreContinuousPosition();
    } else {
      _selectPageForProgress(_pendingProgress, rebuild: true);
    }
  }

  void _restoreContinuousPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 80), () {
        if (!mounted || !_continuousScrollController.hasClients) return;
        _continuousScrollController.jumpTo(
          _pendingProgress *
              _continuousScrollController.position.maxScrollExtent,
        );
      });
    });
  }

  void _selectPageForProgress(double progress, {required bool rebuild}) {
    if (_pageDocuments.isEmpty || _pageStartOffsets.isEmpty) return;
    final totalLength = _documentContentLength(widget.section.content);
    final targetOffset = (totalLength * progress.clamp(0, 1)).round();
    var targetPage = _pageDocuments.length - 1;
    for (var index = 0; index < _pageDocuments.length; index++) {
      final nextStart = index + 1 < _pageStartOffsets.length
          ? _pageStartOffsets[index + 1]
          : totalLength + 1;
      if (targetOffset < nextStart) {
        targetPage = index;
        break;
      }
    }
    if (targetPage == _activePage) return;
    if (rebuild && mounted) {
      setState(() => _activePage = targetPage);
    } else {
      _activePage = targetPage;
    }
  }

  void _schedulePagination() {
    final geometry = _geometry;
    if (geometry == null || _effectiveMode == BookReaderViewMode.continuous) {
      return;
    }
    final request = ++_paginationRequest;
    _paginationTimer?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || request != _paginationRequest) return;
      setState(() => _isPaginating = true);
      _paginationTimer = Timer(
        const Duration(milliseconds: 60),
        () => _beginPagination(request),
      );
    });
  }

  void _beginPagination(int request) {
    if (!mounted || request != _paginationRequest || _geometry == null) return;
    _measuredPages.clear();
    _measurementRetries = 0;
    _installMeasurementDocument(widget.section.content, request);
  }

  void _installMeasurementDocument(RichDocument document, int request) {
    final oldController = _measurementController;
    final oldFocusNode = _measurementFocusNode;
    final oldScrollController = _measurementScrollController;
    final controller = QuillController(
      document: Document.fromJson(document),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
    setState(() {
      _measurementDocument = document;
      _measurementController = controller;
      _measurementFocusNode = FocusNode(canRequestFocus: false);
      _measurementScrollController = ScrollController();
      _measurementEditorKey = GlobalKey<EditorState>();
      _measurementViewportKey = GlobalKey();
    });
    _disposeAfterFrame(oldController, oldFocusNode, oldScrollController);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _measureCurrentDocument(request),
    );
  }

  void _measureCurrentDocument(int request) {
    if (!mounted || request != _paginationRequest) return;
    final editorState = _measurementEditorKey?.currentState;
    final viewportContext = _measurementViewportKey?.currentContext;
    final viewport = viewportContext?.findRenderObject();
    if (editorState == null || viewport is! RenderBox || !viewport.hasSize) {
      if (_measurementRetries++ < 8) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _measureCurrentDocument(request),
        );
      }
      return;
    }
    _measurementRetries = 0;
    final lineHeight = widget.settings.fontSize * widget.settings.lineHeight;
    final bottomSafety = (lineHeight * 1.5).clamp(24, viewport.size.height / 3);
    final probe = viewport.localToGlobal(
      Offset(viewport.size.width - 6, viewport.size.height - bottomSafety),
    );
    final splitOffset = editorState.renderEditor
        .getPositionForOffset(probe)
        .offset;
    final controller = _measurementController;
    final document = _measurementDocument;
    if (controller == null || document == null) return;
    final lastContentOffset = controller.document.length - 1;
    if (splitOffset <= 0) {
      if (_measurementRetries++ < 8) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _measureCurrentDocument(request),
        );
      }
      return;
    }
    if (splitOffset >= lastContentOffset) {
      _finishPagination([..._measuredPages, document], request);
      return;
    }
    final split = BookPagePaginator.split(document, splitOffset);
    _measuredPages.add(split.visible);
    _installMeasurementDocument(split.overflow, request);
  }

  void _finishPagination(List<RichDocument> documents, int request) {
    if (!mounted || request != _paginationRequest) return;
    final oldControllers = List<QuillController>.from(_pageControllers);
    final oldFocusNodes = List<FocusNode>.from(_pageFocusNodes);
    final oldScrollControllers = List<ScrollController>.from(
      _pageScrollControllers,
    );
    _pageControllers.clear();
    _pageFocusNodes.clear();
    _pageScrollControllers.clear();
    _pageEditorKeys.clear();
    _pageViewportKeys.clear();

    final starts = <int>[];
    var offset = 0;
    for (final document in documents) {
      starts.add(offset);
      offset += _pageContentLength(document);
      _pageControllers.add(
        QuillController(
          document: Document.fromJson(document),
          selection: const TextSelection.collapsed(offset: 0),
          readOnly: true,
        ),
      );
      _pageFocusNodes.add(FocusNode(canRequestFocus: false));
      _pageScrollControllers.add(ScrollController());
      _pageEditorKeys.add(GlobalKey<EditorState>());
      _pageViewportKeys.add(GlobalKey());
    }
    _pageDocuments = documents;
    _pageStartOffsets = starts;
    _completedGeometry = _geometry;
    _selectPageForProgress(_pendingProgress, rebuild: false);
    _clearMeasurement(rebuild: false);
    setState(() => _isPaginating = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in oldControllers) {
        controller.dispose();
      }
      for (final node in oldFocusNodes) {
        node.dispose();
      }
      for (final controller in oldScrollControllers) {
        controller.dispose();
      }
    });
  }

  void _invalidatePagination() {
    _paginationTimer?.cancel();
    _paginationRequest++;
    _geometry = null;
    _clearMeasurement();
  }

  void _clearVisiblePages() {
    final oldControllers = List<QuillController>.from(_pageControllers);
    final oldFocusNodes = List<FocusNode>.from(_pageFocusNodes);
    final oldScrollControllers = List<ScrollController>.from(
      _pageScrollControllers,
    );
    _pageControllers.clear();
    _pageFocusNodes.clear();
    _pageScrollControllers.clear();
    _pageEditorKeys.clear();
    _pageViewportKeys.clear();
    _pageDocuments = const [];
    _pageStartOffsets = const [];
    _completedGeometry = null;
    _activePage = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in oldControllers) {
        controller.dispose();
      }
      for (final node in oldFocusNodes) {
        node.dispose();
      }
      for (final controller in oldScrollControllers) {
        controller.dispose();
      }
    });
  }

  void _clearMeasurement({bool rebuild = true}) {
    final oldController = _measurementController;
    final oldFocusNode = _measurementFocusNode;
    final oldScrollController = _measurementScrollController;
    void clear() {
      _measurementDocument = null;
      _measurementController = null;
      _measurementFocusNode = null;
      _measurementScrollController = null;
      _measurementEditorKey = null;
      _measurementViewportKey = null;
    }

    if (rebuild && mounted) {
      setState(clear);
    } else {
      clear();
    }
    _disposeAfterFrame(oldController, oldFocusNode, oldScrollController);
  }

  void _disposeAfterFrame(
    QuillController? controller,
    FocusNode? focusNode,
    ScrollController? scrollController,
  ) {
    if (controller == null && focusNode == null && scrollController == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller?.dispose();
      focusNode?.dispose();
      scrollController?.dispose();
    });
  }

  int _pageContentLength(RichDocument document) {
    final length = _documentContentLength(document);
    final last = document.lastOrNull;
    final attributes = last?['attributes'];
    final hasSoftBreak =
        last?['insert'] == '\n' &&
        attributes is Map &&
        attributes['_bookSoftPageBreak'] == true;
    return length - (hasSoftBreak ? 1 : 0);
  }

  int _documentContentLength(RichDocument document) => document.fold(
    0,
    (length, operation) =>
        length +
        (operation['insert'] is String
            ? (operation['insert'] as String).length
            : 1),
  );

  @override
  void dispose() {
    _progressTimer?.cancel();
    _paginationTimer?.cancel();
    _paginationRequest++;
    _continuousController.dispose();
    _continuousFocusNode.dispose();
    _continuousScrollController.dispose();
    for (final controller in _pageControllers) {
      controller.dispose();
    }
    for (final node in _pageFocusNodes) {
      node.dispose();
    }
    for (final controller in _pageScrollControllers) {
      controller.dispose();
    }
    _measurementController?.dispose();
    _measurementFocusNode?.dispose();
    _measurementScrollController?.dispose();
    super.dispose();
  }
}

class _ReaderPageGeometry {
  const _ReaderPageGeometry({required this.width, required this.height});

  factory _ReaderPageGeometry.fromConstraints(
    BoxConstraints constraints, {
    required BookReaderSettings settings,
    required bool spread,
  }) {
    final stageHorizontalPadding = constraints.maxWidth < 600 ? 48.0 : 72.0;
    const stageVerticalPadding = 24.0;
    const pageGap = 16.0;
    final visiblePages = spread ? 2 : 1;
    final availableWidth = math.max(
      240,
      constraints.maxWidth -
          stageHorizontalPadding -
          pageGap * (visiblePages - 1),
    );
    final maximumWidth = settings.contentWidth + settings.horizontalPadding * 2;
    final width = math.min(maximumWidth, availableWidth / visiblePages);
    final height = math.max(300, constraints.maxHeight - stageVerticalPadding);
    return _ReaderPageGeometry(
      width: width.toDouble(),
      height: height.toDouble(),
    );
  }

  final double width;
  final double height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ReaderPageGeometry &&
          (width - other.width).abs() < 0.5 &&
          (height - other.height).abs() < 0.5;

  @override
  int get hashCode => Object.hash(width.round(), height.round());
}
