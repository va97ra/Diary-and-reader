part of 'book_reader_section_view.dart';

extension _BookReaderContinuousFlow on _BookReaderSectionViewState {
  Widget _buildContinuousView() => BookReaderContinuousView(
    sectionId: widget.section.id,
    settings: widget.settings,
    palette: widget.palette,
    assets: widget.assets,
    controller: _continuousController,
    focusNode: _continuousFocusNode,
    scrollController: _continuousScrollController,
    onPointerDown: _handleContinuousPointerDown,
    onPointerUp: _handleContinuousPointerUp,
    onPointerMove: _handleContinuousPointerMove,
    onPointerSignal: _handleContinuousPointerSignal,
    onPointerCancel: (_) => _resetContinuousPointer(),
    showCursor: widget.speechTargetMode,
    onSpeechTargetSelected: widget.speechTargetMode
        ? (displayOffset) =>
              _selectSpeechTarget(displayOffset: displayOffset, displayStart: 0)
        : null,
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
    _maybeNavigateAtContinuousBoundary();
    if ((next - _progress).abs() < 0.004) return;
    _progress = next;
    _pendingProgress = next;
    _progressTimer?.cancel();
    _progressTimer = Timer(
      const Duration(milliseconds: 350),
      () => widget.onProgressChanged(_progress),
    );
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
}
