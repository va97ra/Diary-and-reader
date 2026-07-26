part of 'book_reader_section_view.dart';

extension _BookReaderPaginationFlow on _BookReaderSectionViewState {
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
                ? BookReaderPageStage(
                    activePage: _activePage,
                    pageCount: _pageControllers.length,
                    viewMode: mode,
                    pageBuilder: (index) => _buildPage(index, geometry),
                    onSelectPage: _selectPage,
                    onPreviousSection: widget.onPreviousSectionRequested,
                    onNextSection: widget.onNextSectionRequested,
                  )
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
                    pageNumber: 1,
                    pageCount: 1,
                    settings: widget.settings,
                    palette: widget.palette,
                    controller: _measurementController!,
                    focusNode: _measurementFocusNode!,
                    scrollController: _measurementScrollController!,
                    editorKey: _measurementEditorKey!,
                    viewportKey: _measurementViewportKey!,
                    assets: widget.assets,
                    showCursor: false,
                    isMeasurement: true,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(int index, _ReaderPageGeometry geometry) =>
      BookReaderPageCard(
        width: geometry.width,
        height: geometry.height,
        pageNumber: index + 1,
        pageCount: _pageControllers.length,
        settings: widget.settings,
        palette: widget.palette,
        controller: _pageControllers[index],
        focusNode: _pageFocusNodes[index],
        scrollController: _pageScrollControllers[index],
        editorKey: _pageEditorKeys[index],
        viewportKey: _pageViewportKeys[index],
        assets: widget.assets,
        showCursor: widget.speechTargetMode,
        onSpeechTargetSelected: widget.speechTargetMode
            ? (localOffset) => _selectSpeechTarget(
                displayOffset: localOffset,
                displayStart: _pageDisplayStartOffsets[index],
              )
            : null,
      );

  void _selectPage(int page) {
    if (page < 0 || page >= _pageControllers.length || page == _activePage) {
      return;
    }
    _mutate(() => _activePage = page);
    final totalLength = _documentContentLength(widget.section.content);
    final offset = _pageStartOffsets[page];
    _progress = totalLength <= 0 ? 0 : (offset / totalLength).clamp(0, 1);
    _pendingProgress = _progress;
    widget.onProgressChanged(_progress);
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
      _mutate(() => _activePage = targetPage);
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
      _mutate(() => _isPaginating = true);
      _paginationTimer = Timer(
        const Duration(milliseconds: 60),
        () => _beginPagination(request),
      );
    });
  }

  void _beginPagination(int request) {
    if (!mounted || request != _paginationRequest || _geometry == null) return;
    _paginationMeasurement.begin();
    _installMeasurementDocument(_displayDocument.document, request);
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
    _mutate(() {
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
      if (_paginationMeasurement.scheduleRetry()) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _measureCurrentDocument(request),
        );
      }
      return;
    }
    _paginationMeasurement.resetRetries();
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
      if (_paginationMeasurement.scheduleRetry()) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _measureCurrentDocument(request),
        );
      }
      return;
    }
    final step = _paginationMeasurement.advance(
      document: document,
      splitOffset: splitOffset,
      lastContentOffset: lastContentOffset,
    );
    if (step.nextDocument case final nextDocument?) {
      _installMeasurementDocument(nextDocument, request);
      return;
    }
    if (step.completedDocuments case final completedDocuments?) {
      _finishPagination(completedDocuments, request);
    }
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
    final displayStarts = <int>[];
    var displayOffset = 0;
    for (final document in documents) {
      displayStarts.add(displayOffset);
      starts.add(_displayDocument.displayToOriginal(displayOffset));
      displayOffset += _pageContentLength(document);
      _pageControllers.add(_pageController(document, displayStarts.last));
      _pageFocusNodes.add(FocusNode());
      _pageScrollControllers.add(ScrollController());
      _pageEditorKeys.add(GlobalKey<EditorState>());
      _pageViewportKeys.add(GlobalKey());
    }
    _pageDocuments = documents;
    _pageStartOffsets = starts;
    _pageDisplayStartOffsets = displayStarts;
    _completedGeometry = _geometry;
    _selectPageForProgress(_pendingProgress, rebuild: false);
    _clearMeasurement(rebuild: false);
    _mutate(() => _isPaginating = false);

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
    _pageDisplayStartOffsets = const [];
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
      _mutate(clear);
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
