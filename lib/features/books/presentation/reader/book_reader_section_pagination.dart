part of 'book_reader_section_view.dart';

extension _BookReaderPaginationFlow on _BookReaderSectionViewState {
  Widget _buildPagedView(
    BuildContext context,
    _ReaderPageGeometry geometry,
    BookReaderViewMode mode,
  ) => ColoredBox(
    key: ValueKey(
      mode == BookReaderViewMode.spread
          ? 'reader-spread-view'
          : 'reader-single-page-view',
    ),
    color: widget.palette.background,
    child: BookReaderPageStage(
      activePage: _activePage,
      pageCount: _pages.length,
      viewMode: mode,
      pageBuilder: (index) => _buildPage(index, geometry),
      onSelectPage: _selectPage,
      onPreviousSection: widget.onPreviousSectionRequested,
      onNextSection: widget.onNextSectionRequested,
      isPaginating: false,
    ),
  );

  Widget _buildPage(int index, _ReaderPageGeometry geometry) =>
      BookReaderPageCard(
        width: geometry.width,
        height: geometry.height,
        pageNumber: index + 1,
        pageCount: _pages.length,
        settings: widget.settings,
        palette: widget.palette,
        layout: _pages[index],
        assets: widget.assets,
        highlights: _renderHighlights,
        selectionGeneration: _selectionGeneration,
        onSelectionChanged: _handleDisplaySelection,
        speechTargetMode: widget.speechTargetMode,
        speechRange: _renderSpeechRange,
        showPageNumber: true,
        onSpeechTargetSelected: widget.speechTargetMode
            ? _selectSpeechTarget
            : null,
      );

  void _ensurePagination(BuildContext context, _ReaderPageGeometry geometry) {
    if (_pages.isNotEmpty && _completedGeometry == geometry) {
      return;
    }
    final metrics = BookReaderPageMetrics.resolve(
      width: geometry.width,
      height: geometry.height,
      settings: widget.settings,
    );
    _pages = _layoutEngine.paginate(
      document: _readerDocument,
      settings: widget.settings,
      palette: widget.palette,
      metrics: metrics,
      locale: Locale(widget.languageCode),
    );
    _completedGeometry = geometry;
    _selectPageForProgress(_pendingProgress, rebuild: false);
  }

  void _selectPage(int page) {
    if (page < 0 || page >= _pages.length || page == _activePage) return;
    _mutate(() => _activePage = page);
    final totalLength = _displayDocument.originalLength;
    final originalOffset = _displayDocument.displayToOriginal(
      _pages[page].sourceStart,
    );
    _progress = totalLength <= 0
        ? 0
        : (originalOffset / totalLength).clamp(0, 1);
    _pendingProgress = _progress;
    widget.onProgressChanged(_progress);
  }

  void _selectPageForProgress(double progress, {required bool rebuild}) {
    if (_pages.isEmpty) return;
    final targetOriginal =
        (_displayDocument.originalLength * progress.clamp(0, 1)).round();
    final targetDisplay = _displayDocument.originalToDisplay(targetOriginal);
    var targetPage = _pages.length - 1;
    for (var index = 0; index < _pages.length; index++) {
      final nextStart = index + 1 < _pages.length
          ? _pages[index + 1].sourceStart
          : _displayDocument.displayLength + 1;
      if (targetDisplay < nextStart) {
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

  void _invalidatePagination() {
    _completedGeometry = null;
    _pages = const [];
  }

  void _clearVisiblePages() {
    _pages = const [];
    _completedGeometry = null;
    _activePage = 0;
  }
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
