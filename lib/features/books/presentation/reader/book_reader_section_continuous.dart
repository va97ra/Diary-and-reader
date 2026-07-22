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
    onPointerCancel: (_) => _resetContinuousPointer(),
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
      widget.onNextSectionRequested?.call();
    } else if (startedAtStart && delta >= 48) {
      widget.onPreviousSectionRequested?.call();
    }
  }

  void _resetContinuousPointer() {
    _continuousPointer = null;
    _continuousPointerStartY = null;
    _continuousPointerStartedAtStart = false;
    _continuousPointerStartedAtEnd = false;
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
