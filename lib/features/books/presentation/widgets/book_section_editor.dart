import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_page_paginator.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_page_view_mode.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/manuscript_statistics.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_editor_metrics.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_formatting_toolbar.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_mobile_editor.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_page_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookSectionEditor extends StatefulWidget {
  const BookSectionEditor({
    required this.section,
    required this.pageFormat,
    required this.paragraphSettings,
    required this.assets,
    required this.onTitleChanged,
    required this.onContentChanged,
    required this.showToolbar,
    required this.usePagedLayout,
    required this.compactA4Preview,
    required this.onExitCompactPreview,
    required this.onInsertImage,
    required this.onInsertPageBreak,
    required this.showPageNavigation,
    required this.viewMode,
    required this.onMetricsChanged,
    this.onControllerReady,
    super.key,
  });

  final BookSection section;
  final BookPageFormat pageFormat;
  final BookParagraphSettings paragraphSettings;
  final Iterable<BookAsset> assets;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<RichDocument> onContentChanged;
  final bool showToolbar;
  final bool usePagedLayout;
  final bool compactA4Preview;
  final VoidCallback onExitCompactPreview;
  final VoidCallback onInsertImage;
  final VoidCallback onInsertPageBreak;
  final bool showPageNavigation;
  final BookPageViewMode viewMode;
  final ValueChanged<BookEditorMetrics> onMetricsChanged;
  final ValueChanged<QuillController>? onControllerReady;

  @override
  State<BookSectionEditor> createState() => BookSectionEditorState();
}

class BookSectionEditorState extends State<BookSectionEditor> {
  final _controllers = <QuillController>[];
  final _focusNodes = <FocusNode>[];
  final _scrollControllers = <ScrollController>[];
  final _editorKeys = <GlobalKey<EditorState>>[];
  final _viewportKeys = <GlobalKey>[];
  late final TextEditingController _titleController;
  late final TextEditingController _measurementTitleController;
  late ManuscriptStatistics _statistics;
  late String _lastManuscriptSignature;

  int _activePage = 0;
  bool _usesPagedLayout = false;
  Timer? _paginationTimer;
  int _paginationRequest = 0;
  int _measurementRetries = 0;
  int _measurementPageNumber = 1;
  final _measuredPages = <RichDocument>[];
  RichDocument? _measurementDocument;
  BookEditorMetrics? _lastReportedMetrics;
  QuillController? _measurementController;
  FocusNode? _measurementFocusNode;
  ScrollController? _measurementScrollController;
  GlobalKey<EditorState>? _measurementEditorKey;
  GlobalKey? _measurementViewportKey;

  QuillController get controller => _controllers[_activePage];
  int get pageCount => _controllers.length;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section.title);
    _measurementTitleController = TextEditingController(
      text: widget.section.title,
    );
    _statistics = ManuscriptStatistics.fromDocument(widget.section.content);
    _lastManuscriptSignature = jsonEncode(widget.section.content);
    _createPageControllers([widget.section.content]);
    _usesPagedLayout = widget.usePagedLayout;
    widget.onControllerReady?.call(controller);
    _scheduleMetricsNotification();
    if (_usesPagedLayout) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _schedulePagination(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant BookSectionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section.title != widget.section.title &&
        _titleController.text != widget.section.title) {
      _titleController.value = TextEditingValue(
        text: widget.section.title,
        selection: TextSelection.collapsed(offset: widget.section.title.length),
      );
      _measurementTitleController.text = widget.section.title;
    }
    if (oldWidget.usePagedLayout && !widget.usePagedLayout) {
      _collapseToMobileDocument();
    }
    final incomingSignature = jsonEncode(widget.section.content);
    final contentChanged = incomingSignature != _lastManuscriptSignature;
    final layoutChanged =
        oldWidget.pageFormat != widget.pageFormat ||
        oldWidget.paragraphSettings != widget.paragraphSettings;
    if (!contentChanged && !layoutChanged) return;
    final manuscript = contentChanged
        ? widget.section.content
        : BookPagePaginator.merge(_pageDocuments);
    _cancelPaginationMeasurement(rebuild: false);
    _disposePageControllers();
    _createPageControllers([manuscript]);
    _activePage = 0;
    _lastManuscriptSignature = jsonEncode(manuscript);
    _statistics = ManuscriptStatistics.fromDocument(manuscript);
    widget.onControllerReady?.call(controller);
    _scheduleMetricsNotification();
    _schedulePagination();
  }

  void _collapseToMobileDocument() {
    final manuscript = BookPagePaginator.merge(_pageDocuments);
    _cancelPaginationMeasurement(rebuild: false);
    _disposePageControllers();
    _createPageControllers([manuscript]);
    _activePage = 0;
    _lastManuscriptSignature = jsonEncode(manuscript);
    _statistics = ManuscriptStatistics.fromDocument(manuscript);
    widget.onControllerReady?.call(controller);
    _scheduleMetricsNotification();
  }

  void _createPageControllers(
    List<RichDocument> documents, {
    int selectionPage = 0,
    int selectionOffset = 0,
  }) {
    for (var index = 0; index < documents.length; index++) {
      final document = documents[index];
      final documentLength = _documentLength(document);
      final controller = QuillController(
        document: Document.fromJson(document),
        selection: TextSelection.collapsed(
          offset: index == selectionPage
              ? selectionOffset.clamp(0, documentLength - 1)
              : 0,
        ),
      );
      controller.addListener(() => _handleDocumentChanged(controller));
      _controllers.add(controller);

      final focusNode = FocusNode();
      focusNode.addListener(() => _activatePage(focusNode));
      _focusNodes.add(focusNode);
      _scrollControllers.add(ScrollController());
      _editorKeys.add(GlobalKey<EditorState>());
      _viewportKeys.add(GlobalKey());
    }
  }

  void _handleDocumentChanged(QuillController changedController) {
    final index = _controllers.indexOf(changedController);
    if (index < 0) return;
    final manuscript = BookPagePaginator.merge(_pageDocuments);
    final signature = jsonEncode(manuscript);
    if (signature == _lastManuscriptSignature) return;
    _lastManuscriptSignature = signature;
    _statistics = ManuscriptStatistics.fromDocument(manuscript);
    widget.onContentChanged(manuscript);
    _scheduleMetricsNotification();
    if (_usesPagedLayout) _schedulePagination();
  }

  void _activatePage(FocusNode changedNode) {
    final index = _focusNodes.indexOf(changedNode);
    if (index < 0 || !changedNode.hasFocus || index == _activePage) return;
    setState(() => _activePage = index);
    widget.onControllerReady?.call(controller);
    _scheduleMetricsNotification();
  }

  List<RichDocument> get _pageDocuments => _controllers
      .map(
        (controller) => controller.document
            .toDelta()
            .toJson()
            .map((operation) => Map<String, dynamic>.from(operation))
            .toList(),
      )
      .toList();

  void _schedulePagination() {
    final request = ++_paginationRequest;
    _paginationTimer?.cancel();
    _paginationTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted || !_usesPagedLayout || request != _paginationRequest) {
        return;
      }
      _beginPaginationMeasurement(request);
    });
  }

  void _beginPaginationMeasurement(int request) {
    final manuscript = BookPagePaginator.merge(_pageDocuments);
    _measuredPages.clear();
    _measurementPageNumber = 1;
    _measurementRetries = 0;
    _installMeasurementDocument(manuscript, request);
  }

  void _installMeasurementDocument(RichDocument document, int request) {
    final oldController = _measurementController;
    final oldFocusNode = _measurementFocusNode;
    final oldScrollController = _measurementScrollController;
    final controller = QuillController(
      document: Document.fromJson(document),
      selection: const TextSelection.collapsed(offset: 0),
    );
    setState(() {
      _measurementDocument = document;
      _measurementController = controller;
      _measurementFocusNode = FocusNode();
      _measurementScrollController = ScrollController();
      _measurementEditorKey = GlobalKey<EditorState>();
      _measurementViewportKey = GlobalKey();
    });
    _disposeMeasurementResourcesAfterFrame(
      oldController,
      oldFocusNode,
      oldScrollController,
    );
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
      if (_measurementRetries++ < 6) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _measureCurrentDocument(request),
        );
      }
      return;
    }
    _measurementRetries = 0;

    final lineHeight =
        BookPageFormat.pointsToLogicalPixels(
          widget.paragraphSettings.fontSizePt,
        ) *
        widget.paragraphSettings.lineHeight;
    final paragraphSpacing = BookPageFormat.pointsToLogicalPixels(
      widget.paragraphSettings.spacingAfterPt,
    );
    final bottomSafety = (lineHeight * 2 + paragraphSpacing).clamp(
      32,
      viewport.size.height / 3,
    );
    final probe = viewport.localToGlobal(
      Offset(viewport.size.width - 8, viewport.size.height - bottomSafety),
    );
    final splitOffset = editorState.renderEditor
        .getPositionForOffset(probe)
        .offset;
    final controller = _measurementController;
    final document = _measurementDocument;
    if (controller == null || document == null) return;
    final lastContentOffset = controller.document.length - 1;
    if (splitOffset <= 0) {
      if (_measurementRetries++ < 6) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _measureCurrentDocument(request),
        );
      }
      return;
    }

    final hardPageSplit = BookPagePaginator.splitAtFirstHardPageBreak(
      document,
      splitOffset,
    );
    if (hardPageSplit != null) {
      _measuredPages.add(hardPageSplit.visible);
      _measurementPageNumber++;
      _installMeasurementDocument(hardPageSplit.overflow, request);
      return;
    }
    if (splitOffset >= lastContentOffset) {
      _finishPaginationMeasurement([..._measuredPages, document], request);
      return;
    }

    final split = BookPagePaginator.split(document, splitOffset);
    _measuredPages.add(split.visible);
    _measurementPageNumber++;
    _installMeasurementDocument(split.overflow, request);
  }

  void _finishPaginationMeasurement(List<RichDocument> documents, int request) {
    if (!mounted || request != _paginationRequest) return;
    final currentDocuments = _pageDocuments;
    final unchanged = jsonEncode(currentDocuments) == jsonEncode(documents);
    if (unchanged) {
      _clearMeasurementWidget();
      return;
    }

    final globalSelection = _globalSelectionOffset(currentDocuments);
    final target = _selectionForDocuments(documents, globalSelection);
    _clearMeasurementWidget(rebuild: false);
    _disposePageControllers();
    _createPageControllers(
      documents,
      selectionPage: target.page,
      selectionOffset: target.offset,
    );
    setState(() => _activePage = target.page);
    final manuscript = BookPagePaginator.merge(documents);
    _lastManuscriptSignature = jsonEncode(manuscript);
    widget.onContentChanged(manuscript);
    widget.onControllerReady?.call(controller);
    _scheduleMetricsNotification();
  }

  void _selectPage(int page) {
    if (page < 0 || page >= _controllers.length || page == _activePage) return;
    setState(() => _activePage = page);
    widget.onControllerReady?.call(controller);
    _scheduleMetricsNotification();
  }

  void revealTextRange(int globalOffset, int length) {
    final target = _selectionForDocuments(_pageDocuments, globalOffset);
    if (target.page != _activePage) {
      setState(() => _activePage = target.page);
      widget.onControllerReady?.call(controller);
      _scheduleMetricsNotification();
    }
    final end = (target.offset + length).clamp(
      target.offset,
      controller.document.length - 1,
    );
    controller.updateSelection(
      TextSelection(baseOffset: target.offset, extentOffset: end),
      ChangeSource.local,
    );
    _focusNodes[_activePage].requestFocus();
  }

  int _globalSelectionOffset(List<RichDocument> documents) {
    var offset = 0;
    for (var index = 0; index < _activePage; index++) {
      offset += _pageContentLength(documents[index]);
    }
    return offset + controller.selection.extentOffset;
  }

  ({int page, int offset}) _selectionForDocuments(
    List<RichDocument> documents,
    int globalOffset,
  ) {
    var remaining = globalOffset;
    for (var index = 0; index < documents.length; index++) {
      final contentLength = _pageContentLength(documents[index]);
      final isLast = index == documents.length - 1;
      if (remaining < contentLength || isLast) {
        return (
          page: index,
          offset: remaining.clamp(0, _documentLength(documents[index]) - 1),
        );
      }
      remaining -= contentLength;
    }
    return (page: 0, offset: 0);
  }

  int _pageContentLength(RichDocument document) =>
      _documentLength(document) - (_hasSoftPageBreak(document) ? 1 : 0);

  int _documentLength(RichDocument document) => document.fold(
    0,
    (length, operation) =>
        length +
        (operation['insert'] is String
            ? (operation['insert'] as String).length
            : 1),
  );

  bool _hasSoftPageBreak(RichDocument document) {
    if (document.isEmpty || document.last['insert'] != '\n') return false;
    final attributes = document.last['attributes'];
    return attributes is Map && attributes['_bookSoftPageBreak'] == true;
  }

  void _cancelPaginationMeasurement({bool rebuild = true}) {
    _paginationTimer?.cancel();
    _paginationRequest++;
    _clearMeasurementWidget(rebuild: rebuild);
  }

  void _clearMeasurementWidget({bool rebuild = true}) {
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
    _disposeMeasurementResourcesAfterFrame(
      oldController,
      oldFocusNode,
      oldScrollController,
    );
  }

  void _disposeMeasurementResourcesAfterFrame(
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

  @override
  Widget build(BuildContext context) {
    final pagedLayoutChanged = _usesPagedLayout != widget.usePagedLayout;
    _usesPagedLayout = widget.usePagedLayout;
    if (pagedLayoutChanged && _usesPagedLayout) _schedulePagination();

    return Column(
      children: [
        if (widget.showToolbar)
          BookFormattingToolbar(
            controller: controller,
            paragraphSettings: widget.paragraphSettings,
            onInsertImage: widget.onInsertImage,
            onInsertPageBreak: widget.onInsertPageBreak,
          ),
        Expanded(
          child: widget.usePagedLayout
              ? _buildPagedEditorWithMeasurement()
              : BookMobileEditor(
                  controller: controller,
                  focusNode: _focusNodes[_activePage],
                  scrollController: _scrollControllers[_activePage],
                  titleController: _titleController,
                  onTitleChanged: widget.onTitleChanged,
                  pageNumber: _activePage + 1,
                  pageCount: _controllers.length,
                  pageFormat: widget.pageFormat,
                  paragraphSettings: widget.paragraphSettings,
                  assets: widget.assets,
                  onPreviousPage: _activePage > 0
                      ? () => _selectPage(_activePage - 1)
                      : null,
                  onNextPage: _activePage < _controllers.length - 1
                      ? () => _selectPage(_activePage + 1)
                      : null,
                  showPageNavigation: widget.showPageNavigation,
                ),
        ),
      ],
    );
  }

  void _scheduleMetricsNotification() {
    final metrics = BookEditorMetrics(
      words: _statistics.words,
      activePage: _activePage + 1,
      pageCount: _controllers.length,
    );
    if (_lastReportedMetrics == metrics) return;
    _lastReportedMetrics = metrics;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _lastReportedMetrics == metrics) {
        widget.onMetricsChanged(metrics);
      }
    });
  }

  Widget _buildPagedEditorWithMeasurement() => Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned.fill(child: _buildPagedEditor()),
      if (_measurementController != null)
        Positioned(
          left: -widget.pageFormat.width * 2,
          top: 0,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0,
                child: BookPageCanvas(
                  pageNumber: _measurementPageNumber,
                  scale: 1,
                  pageFormat: widget.pageFormat,
                  paragraphSettings: widget.paragraphSettings,
                  assets: widget.assets,
                  controller: _measurementController!,
                  focusNode: _measurementFocusNode!,
                  scrollController: _measurementScrollController!,
                  editorKey: _measurementEditorKey!,
                  viewportKey: _measurementViewportKey!,
                  titleController: _measurementTitleController,
                  onTitleChanged: (_) {},
                  isMeasurement: true,
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _buildPagedEditor() => ColoredBox(
    color: const Color(0xFF141824),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (widget.compactA4Preview) {
          return _buildSinglePage(constraints, compact: true);
        }
        return switch (widget.viewMode) {
          BookPageViewMode.continuous => _buildContinuousPages(constraints),
          BookPageViewMode.singlePage => _buildSinglePage(constraints),
          BookPageViewMode.spread => _buildPageSpread(constraints),
        };
      },
    ),
  );

  Widget _buildContinuousPages(BoxConstraints constraints) {
    const horizontalPadding = 32.0;
    final scale = widget.pageFormat.scaleForWidth(
      constraints.maxWidth - horizontalPadding * 2,
    );
    return ListView.separated(
      key: const ValueKey('continuous-page-view'),
      padding: const EdgeInsets.fromLTRB(
        horizontalPadding,
        24,
        horizontalPadding,
        96,
      ),
      itemCount: _controllers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 24),
      itemBuilder: (context, index) => Center(child: _buildPage(index, scale)),
    );
  }

  Widget _buildSinglePage(BoxConstraints constraints, {bool compact = false}) =>
      _buildPageStage(
        key: ValueKey(compact ? 'mobile-a4-page-preview' : 'single-page-view'),
        constraints: constraints,
        pageIndices: [_activePage],
        previousPage: _activePage > 0 ? _activePage - 1 : null,
        nextPage: _activePage < _controllers.length - 1
            ? _activePage + 1
            : null,
        compact: compact,
      );

  Widget _buildPageSpread(BoxConstraints constraints) {
    final firstPage = (_activePage ~/ 2) * 2;
    return _buildPageStage(
      key: const ValueKey('two-page-spread-view'),
      constraints: constraints,
      pageIndices: [
        firstPage,
        if (firstPage + 1 < _controllers.length) firstPage + 1,
      ],
      previousPage: firstPage > 0 ? firstPage - 2 : null,
      nextPage: firstPage + 2 < _controllers.length ? firstPage + 2 : null,
    );
  }

  Widget _buildPageStage({
    required Key key,
    required BoxConstraints constraints,
    required List<int> pageIndices,
    required int? previousPage,
    required int? nextPage,
    bool compact = false,
  }) {
    final horizontalPadding = compact ? 24.0 : 76.0;
    final verticalPadding = compact ? 24.0 : 36.0;
    final compactControlsHeight = compact ? 64.0 : 0.0;
    const pageGap = 18.0;
    final naturalWidth =
        widget.pageFormat.width * pageIndices.length +
        pageGap * (pageIndices.length - 1);
    final widthScale =
        (constraints.maxWidth - horizontalPadding) / naturalWidth;
    final heightScale =
        (constraints.maxHeight - verticalPadding - compactControlsHeight) /
        widget.pageFormat.height;
    final scale = math
        .min(1, math.min(widthScale, heightScale))
        .clamp(0.1, 1.0)
        .toDouble();
    final strings = AppStrings.of(context);

    final pages = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < pageIndices.length; index++) ...[
          if (index > 0) const SizedBox(width: pageGap),
          IgnorePointer(
            ignoring: compact,
            child: _buildPage(pageIndices[index], scale),
          ),
        ],
      ],
    );

    return Stack(
      key: key,
      children: [
        if (compact)
          Positioned.fill(
            bottom: compactControlsHeight,
            child: Center(child: pages),
          )
        else
          Center(child: pages),
        if (compact)
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (previousPage != null)
                  IconButton.filledTonal(
                    key: const ValueKey('book-page-previous'),
                    tooltip: strings.previousPage,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _selectPage(previousPage),
                    icon: const Icon(Icons.chevron_left),
                  ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  key: const ValueKey('mobile-a4-edit-button'),
                  onPressed: widget.onExitCompactPreview,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(strings.comfortableWriting),
                ),
                const SizedBox(width: 12),
                if (nextPage != null)
                  IconButton.filledTonal(
                    key: const ValueKey('book-page-next'),
                    tooltip: strings.nextPage,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _selectPage(nextPage),
                    icon: const Icon(Icons.chevron_right),
                  ),
              ],
            ),
          )
        else if (!compact) ...[
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filledTonal(
                key: const ValueKey('book-page-previous'),
                tooltip: strings.previousPage,
                onPressed: previousPage == null
                    ? null
                    : () => _selectPage(previousPage),
                icon: const Icon(Icons.chevron_left),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filledTonal(
                key: const ValueKey('book-page-next'),
                tooltip: strings.nextPage,
                onPressed: nextPage == null
                    ? null
                    : () => _selectPage(nextPage),
                icon: const Icon(Icons.chevron_right),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPage(int index, double scale) => BookPageCanvas(
    pageNumber: index + 1,
    scale: scale,
    pageFormat: widget.pageFormat,
    paragraphSettings: widget.paragraphSettings,
    assets: widget.assets,
    controller: _controllers[index],
    focusNode: _focusNodes[index],
    scrollController: _scrollControllers[index],
    editorKey: _editorKeys[index],
    viewportKey: _viewportKeys[index],
    titleController: _titleController,
    onTitleChanged: widget.onTitleChanged,
  );

  @override
  void dispose() {
    _paginationTimer?.cancel();
    _paginationRequest++;
    _measurementController?.dispose();
    _measurementFocusNode?.dispose();
    _measurementScrollController?.dispose();
    _disposePageControllers();
    _titleController.dispose();
    _measurementTitleController.dispose();
    super.dispose();
  }

  void _disposePageControllers() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    for (final scrollController in _scrollControllers) {
      scrollController.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
    _scrollControllers.clear();
    _editorKeys.clear();
    _viewportKeys.clear();
  }
}
