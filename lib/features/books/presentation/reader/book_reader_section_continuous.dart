part of 'book_reader_section_view.dart';

extension _BookReaderContinuousFlow on _BookReaderSectionViewState {
  Widget _buildContinuousView() => BookReaderContinuousView(
    sectionId: widget.section.id,
    document: _readerDocument,
    settings: widget.settings,
    palette: widget.palette,
    assets: widget.assets,
    scrollController: _continuousScrollController,
    controller: _continuousController,
    initialDisplayOffset: _displayOffsetFor(_pendingProgress),
    edgeInsets: widget.readingInsets,
    highlights: _renderHighlights,
    selectionGeneration: _selectionGeneration,
    onSelectionChanged: _handleDisplaySelection,
    onPointerDown: _handleContinuousPointerDown,
    onPointerUp: _handleContinuousPointerUp,
    onPointerMove: _handleContinuousPointerMove,
    onPointerSignal: _handleContinuousPointerSignal,
    onPointerCancel: (_) => _resetContinuousPointer(),
    onUserScroll: widget.onUserNavigation,
    speechTargetMode: widget.speechTargetMode,
    speechRange: _renderSpeechRange,
    onSpeechTargetSelected: widget.speechTargetMode
        ? _selectSpeechTarget
        : null,
  );

  void _handleContinuousScroll() {
    if (!_continuousScrollController.hasClients ||
        _effectiveMode != BookReaderViewMode.continuous) {
      return;
    }
    _maybeNavigateAtContinuousBoundary();
    _progressTimer?.cancel();
    _progressTimer = Timer(
      const Duration(milliseconds: 350),
      _reportContinuousProgress,
    );
  }

  /// Progress is the share of the chapter text above the viewport, the same
  /// measure the paged view uses, so switching modes keeps the place.
  void _reportContinuousProgress() {
    if (!mounted ||
        !_continuousScrollController.hasClients ||
        _effectiveMode != BookReaderViewMode.continuous) {
      return;
    }
    final position = _continuousScrollController.position;
    final double next;
    if (position.extentAfter <= 1 && position.extentBefore > 1) {
      next = 1;
    } else {
      final top = _continuousController.topOffset;
      if (top == null) return;
      final total = _displayDocument.originalLength;
      next = total <= 0
          ? 0
          : (_displayDocument.displayToOriginal(top) / total)
                .clamp(0, 1)
                .toDouble();
    }
    if ((next - _progress).abs() < 0.001) return;
    _progress = next;
    _pendingProgress = next;
    widget.onProgressChanged(next);
  }

  void _handleContinuousPointerMove(PointerMoveEvent event) {
    if (_continuousPointer != event.pointer ||
        _continuousPointerStartY == null) {
      return;
    }
    final delta = event.position.dy - _continuousPointerStartY!;
    if (delta <= -12) _continuousForwardInput = true;
    if (delta >= 12) _continuousBackwardInput = true;
  }

  void _handleContinuousPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent ||
        _effectiveMode != BookReaderViewMode.continuous) {
      return;
    }
    if (event.scrollDelta.dy > 0) _continuousForwardInput = true;
    if (event.scrollDelta.dy < 0) _continuousBackwardInput = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeNavigateAtContinuousBoundary(),
    );
  }

  void _maybeNavigateAtContinuousBoundary() {
    if (!_continuousScrollController.hasClients || _navigationLocked) return;
    final position = _continuousScrollController.position;
    if (_continuousForwardInput && position.extentAfter <= 1) {
      _continuousForwardInput = false;
      _requestSectionNavigation(1);
    } else if (_continuousBackwardInput && position.extentBefore <= 1) {
      _continuousBackwardInput = false;
      _requestSectionNavigation(-1);
    }
  }

  void _handleContinuousPointerDown(PointerDownEvent event) {
    if (!widget.settings.swipeChapterNavigation ||
        _continuousPointer != null ||
        !_continuousScrollController.hasClients ||
        _effectiveMode != BookReaderViewMode.continuous) {
      return;
    }
    final position = _continuousScrollController.position;
    _continuousPointer = event.pointer;
    _continuousPointerStartY = event.position.dy;
    _continuousPointerStartedAtStart = position.extentBefore <= 1;
    _continuousPointerStartedAtEnd = position.extentAfter <= 1;
  }

  void _handleContinuousPointerUp(PointerUpEvent event) {
    if (_continuousPointer != event.pointer ||
        _continuousPointerStartY == null) {
      return;
    }
    final delta = event.position.dy - _continuousPointerStartY!;
    final startedAtStart = _continuousPointerStartedAtStart;
    final startedAtEnd = _continuousPointerStartedAtEnd;
    _resetContinuousPointer();
    if (startedAtEnd && delta <= -48) {
      _requestSectionNavigation(1);
    } else if (startedAtStart && delta >= 48) {
      _requestSectionNavigation(-1);
    }
  }

  void _resetContinuousPointer() {
    _continuousPointer = null;
    _continuousPointerStartY = null;
    _continuousPointerStartedAtStart = false;
    _continuousPointerStartedAtEnd = false;
    _continuousForwardInput = false;
    _continuousBackwardInput = false;
  }

  void _restoreContinuousPosition() =>
      _continuousController.reveal(_displayOffsetFor(_pendingProgress));
}
