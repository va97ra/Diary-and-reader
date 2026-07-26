part of 'book_reader_section_view.dart';

extension _BookReaderPaginationFlow on _BookReaderSectionViewState {
  Widget _buildPagedView(
    BuildContext context,
    _ReaderPageGeometry geometry,
    BookReaderViewMode mode,
  ) {
    final pagesMatchGeometry =
        _pageDocuments.isNotEmpty && _completedGeometry == geometry;
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
                    pageCount: _pageDocuments.length,
                    viewMode: mode,
                    pageBuilder: (index) => _buildPage(index, geometry),
                    onSelectPage: _selectPage,
                    onPreviousSection: widget.onPreviousSectionRequested,
                    onNextSection: widget.onNextSectionRequested,
                    isPaginating: _isPaginating,
                  )
                : const Center(
                    key: ValueKey('reader-page-loading'),
                    child: CircularProgressIndicator(),
                  ),
          ),
          if (_isPaginating && pagesMatchGeometry)
            const Positioned(
              key: ValueKey('reader-page-background-loading'),
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
                    showPageNumber: false,
                    isMeasurement: true,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(int index, _ReaderPageGeometry geometry) {
    final resources = _resourcesForPage(index);
    return BookReaderPageCard(
      width: geometry.width,
      height: geometry.height,
      pageNumber: index + 1,
      pageCount: _pageDocuments.length,
      settings: widget.settings,
      palette: widget.palette,
      controller: resources.controller,
      focusNode: resources.focusNode,
      scrollController: resources.scrollController,
      editorKey: resources.editorKey,
      viewportKey: resources.viewportKey,
      assets: widget.assets,
      showCursor: widget.speechTargetMode,
      showPageNumber: !_isPaginating,
      onSpeechTargetSelected: widget.speechTargetMode
          ? (localOffset) => _selectSpeechTarget(
              displayOffset: localOffset,
              displayStart: _pageDisplayStartOffsets[index],
            )
          : null,
    );
  }

  _ReaderPageResources _resourcesForPage(int index) =>
      _pageResources.putIfAbsent(
        index,
        () => _ReaderPageResources(
          controller: _pageController(
            _pageDocuments[index],
            _pageDisplayStartOffsets[index],
          ),
          focusNode: FocusNode(),
          scrollController: ScrollController(),
          editorKey: GlobalKey<EditorState>(),
          viewportKey: GlobalKey(),
        ),
      );

  void _selectPage(int page) {
    if (page < 0 || page >= _pageDocuments.length || page == _activePage) {
      return;
    }
    _mutate(() => _activePage = page);
    _schedulePageResourcePruning();
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
    _allowProgressivePagination =
        _pageDocuments.isEmpty && _pendingProgress <= 0.004;
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
      } else {
        _finishPaginationWithCurrentDocument(request);
      }
      return;
    }
    _paginationMeasurement.resetRetries();
    final lineHeight = widget.settings.fontSize * widget.settings.lineHeight;
    final maximumBottomSafety = math.max(1.0, viewport.size.height / 3);
    final bottomSafety = (lineHeight * 1.5).clamp(
      math.min(24.0, maximumBottomSafety),
      maximumBottomSafety,
    );
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
      } else {
        _finishPaginationWithCurrentDocument(request);
      }
      return;
    }
    final step = _paginationMeasurement.advance(
      document: document,
      splitOffset: splitOffset,
      lastContentOffset: lastContentOffset,
    );
    if (step.nextDocument case final nextDocument?) {
      _publishPaginationProgress(request);
      _installMeasurementDocument(nextDocument, request);
      return;
    }
    if (step.completedDocuments case final completedDocuments?) {
      _finishPagination(completedDocuments, request);
    }
  }

  void _finishPaginationWithCurrentDocument(int request) {
    final document = _measurementDocument;
    if (document == null) {
      _clearMeasurement(rebuild: false);
      _mutate(() => _isPaginating = false);
      return;
    }
    _finishPagination([
      ..._paginationMeasurement.completedPages,
      document,
    ], request);
  }

  void _finishPagination(List<RichDocument> documents, int request) {
    if (!mounted || request != _paginationRequest) return;
    final preserveResources = _hasSamePagePrefix(_pageDocuments, documents);
    final oldResources = preserveResources
        ? const <_ReaderPageResources>[]
        : _takePageResources();

    _installPageDocuments(documents);
    _allowProgressivePagination = false;
    _selectPageForProgress(_pendingProgress, rebuild: false);
    _clearMeasurement(rebuild: false);
    _mutate(() => _isPaginating = false);

    _disposePageResourcesAfterFrame(oldResources);
  }

  void _publishPaginationProgress(int request) {
    if (!_allowProgressivePagination || request != _paginationRequest) return;
    final documents = _paginationMeasurement.completedPages.toList(
      growable: false,
    );
    if (documents.isEmpty) return;
    _installPageDocuments(documents);
  }

  void _installPageDocuments(List<RichDocument> documents) {
    final starts = <int>[];
    final displayStarts = <int>[];
    var displayOffset = 0;
    for (final document in documents) {
      displayStarts.add(displayOffset);
      starts.add(_displayDocument.displayToOriginal(displayOffset));
      displayOffset += _pageContentLength(document);
    }
    _pageDocuments = documents;
    _pageStartOffsets = starts;
    _pageDisplayStartOffsets = displayStarts;
    _completedGeometry = _geometry;
  }

  bool _hasSamePagePrefix(
    List<RichDocument> current,
    List<RichDocument> replacement,
  ) {
    if (current.length > replacement.length) return false;
    for (var index = 0; index < current.length; index++) {
      if (!identical(current[index], replacement[index])) return false;
    }
    return true;
  }

  void _invalidatePagination() {
    _paginationTimer?.cancel();
    _paginationRequest++;
    _allowProgressivePagination = false;
    _geometry = null;
    _clearMeasurement();
  }

  void _clearVisiblePages() {
    final oldResources = _takePageResources();
    _pageDocuments = const [];
    _pageStartOffsets = const [];
    _pageDisplayStartOffsets = const [];
    _completedGeometry = null;
    _activePage = 0;
    _allowProgressivePagination = false;
    _disposePageResourcesAfterFrame(oldResources);
  }

  List<_ReaderPageResources> _takePageResources() {
    final resources = _pageResources.values.toList(growable: false);
    _pageResources.clear();
    return resources;
  }

  void _schedulePageResourcePruning() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pageResources.length <= 4) return;
      final firstVisible = _effectiveMode == BookReaderViewMode.spread
          ? (_activePage ~/ 2) * 2
          : _activePage;
      final lastVisible = _effectiveMode == BookReaderViewMode.spread
          ? math.min(firstVisible + 1, _pageDocuments.length - 1)
          : firstVisible;
      final keepFrom = math.max(0, firstVisible - 1);
      final keepThrough = math.min(_pageDocuments.length - 1, lastVisible + 1);
      final stale = <_ReaderPageResources>[];
      _pageResources.removeWhere((page, resources) {
        final remove = page < keepFrom || page > keepThrough;
        if (remove) stale.add(resources);
        return remove;
      });
      for (final resources in stale) {
        resources.dispose();
      }
    });
  }

  void _disposePageResourcesAfterFrame(
    Iterable<_ReaderPageResources> resources,
  ) {
    if (resources.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final item in resources) {
        item.dispose();
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
    const stageHorizontalPadding = 0.0;
    const stageVerticalPadding = 0.0;
    const pageGap = 16.0;
    final visiblePages = spread ? 2 : 1;
    final availableWidth = math.max(
      1,
      constraints.maxWidth -
          stageHorizontalPadding -
          pageGap * (visiblePages - 1),
    );
    final maximumWidth = settings.contentWidth + settings.horizontalPadding * 2;
    final width = math.max(
      1,
      math.min(maximumWidth, availableWidth / visiblePages),
    );
    final height = math.max(1, constraints.maxHeight - stageVerticalPadding);
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
