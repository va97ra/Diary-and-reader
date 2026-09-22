part of 'book_reader_section_view.dart';

/// Layout time allowed inside a frame when a page must appear right away.
const _foregroundPaginationBudget = Duration(milliseconds: 12);

/// Layout time per background slice; frames still render between slices.
const _backgroundPaginationBudget = Duration(milliseconds: 8);

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
    child: _awaitingPage
        ? Center(
            child: SizedBox(
              key: const ValueKey('reader-page-loading'),
              width: geometry.width,
              height: geometry.height,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        : BookReaderPageStage(
            activePage: _activePage,
            pageCount: _pages.length,
            viewMode: mode,
            pageBuilder: (index) => _buildPage(index, geometry),
            onSelectPage: _selectPage,
            onPreviousSection: widget.onPreviousSectionRequested,
            onNextSection: widget.onNextSectionRequested,
            isPaginating: !(_pagination?.isComplete ?? true),
          ),
  );

  Widget _buildPage(int index, _ReaderPageGeometry geometry) =>
      BookReaderPageCard(
        width: geometry.width,
        height: geometry.height,
        pageNumber: index + 1,
        pageCount: (_pagination?.isComplete ?? false) ? _pages.length : null,
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
    if (_pagination == null || _completedGeometry != geometry) {
      _pagination = _layoutEngine.paginate(
        document: _readerDocument,
        settings: widget.settings,
        palette: widget.palette,
        metrics: BookReaderPageMetrics.resolve(
          width: geometry.width,
          height: geometry.height,
          settings: widget.settings,
        ),
        locale: Locale(widget.languageCode),
      );
      _completedGeometry = geometry;
      _awaitingPage = true;
    }
    if (_awaitingPage) _advanceToPendingPage(_foregroundPaginationBudget);
    _schedulePaginationSlice();
  }

  /// Lays out pages up to the reading position and shows it once ready.
  void _advanceToPendingPage(Duration budget) {
    final pagination = _pagination;
    if (pagination == null) return;
    final clock = Stopwatch()..start();
    final target = _displayOffsetFor(_pendingProgress);
    pagination.advance(budget: budget, targetOffset: target);
    if (!pagination.covers(target)) return;
    _awaitingPage = false;
    _selectPageForProgress(_pendingProgress, rebuild: false);
    // The facing and the next page too, so the first turn is instant.
    final remaining = budget - clock.elapsed;
    if (remaining > Duration.zero) {
      pagination.advance(budget: remaining, minPageCount: _activePage + 3);
    }
  }

  void _schedulePaginationSlice() {
    final pagination = _pagination;
    if (pagination == null ||
        pagination.isComplete ||
        _paginationSliceTimer != null) {
      return;
    }
    _paginationSliceTimer = Timer(Duration.zero, () {
      _paginationSliceTimer = null;
      if (!mounted || !identical(pagination, _pagination)) return;
      final wasAwaiting = _awaitingPage;
      if (wasAwaiting) {
        _advanceToPendingPage(_backgroundPaginationBudget);
      } else {
        pagination.advance(budget: _backgroundPaginationBudget);
      }
      // Rebuild only to show the awaited page or the final page count.
      if (pagination.isComplete || wasAwaiting && !_awaitingPage) {
        _mutate(() {});
      }
      _schedulePaginationSlice();
    });
  }

  void _selectPage(int page) {
    if (page < 0 || page >= _pages.length || page == _activePage) return;
    widget.onUserNavigation();
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
    final pagination = _pagination;
    if (pagination == null) return;
    final targetDisplay = _displayOffsetFor(progress);
    if (!pagination.covers(targetDisplay)) {
      if (rebuild && mounted) {
        _mutate(() => _awaitingPage = true);
      } else {
        _awaitingPage = true;
      }
      _schedulePaginationSlice();
      return;
    }
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

  /// Makes sure [page] is laid out; the turn is skipped while it is not.
  bool _hasPage(int page) {
    final pagination = _pagination;
    if (pagination == null) return false;
    if (page >= pagination.pages.length && !pagination.isComplete) {
      pagination.advance(
        budget: _foregroundPaginationBudget,
        minPageCount: page + 1,
      );
    }
    return page < pagination.pages.length;
  }

  void _invalidatePagination() {
    _completedGeometry = null;
    _pagination = null;
    _awaitingPage = false;
  }

  void _clearVisiblePages() {
    _invalidatePagination();
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
          width.round() == other.width.round() &&
          height.round() == other.height.round();

  @override
  int get hashCode => Object.hash(width.round(), height.round());
}
