part of 'book_reader_section_view.dart';

extension _BookReaderDocumentFlow on _BookReaderSectionViewState {
  /// Resolving an anchor scans the chapter text, so the result is kept until
  /// the highlights or the displayed text change.
  List<BookReaderRenderHighlight> get _renderHighlights {
    if (identical(widget.highlights, _highlightSource) &&
        identical(_displayDocument, _highlightDocument)) {
      return _highlightCache;
    }
    _highlightSource = widget.highlights;
    _highlightDocument = _displayDocument;
    return _highlightCache = [
      for (final highlight in widget.highlights)
        if (highlight.sectionId == widget.section.id)
          (() {
            final resolved = BookReaderTextAnchor.resolve(
              text: _plainText,
              startOffset: highlight.startOffset,
              endOffset: highlight.endOffset,
              excerpt: highlight.excerpt,
              sectionProgress: highlight.sectionProgress,
            );
            return BookReaderRenderHighlight(
              start: _displayDocument.originalToDisplay(resolved.start),
              end: _displayDocument.originalToDisplay(resolved.end),
              color: highlight.color,
            );
          })(),
    ];
  }

  BookReaderTextRange? get _renderSpeechRange {
    final range = widget.speechRange;
    if (range == null) return null;
    return BookReaderTextRange(
      _displayDocument.originalToDisplay(range.start),
      _displayDocument.originalToDisplay(range.end),
    );
  }

  void _selectSpeechTarget(int displayOffset) {
    final originalOffset = _displayDocument.displayToOriginal(displayOffset);
    widget.onSpeechTargetSelected(
      originalOffset.clamp(0, _displayDocument.originalLength),
    );
  }

  void _handleDisplaySelection(TextSelection? selection) {
    if (selection == null || selection.isCollapsed) {
      widget.onTextSelection(null);
      return;
    }
    final mappedSelection = TextSelection(
      baseOffset: _displayDocument.displayToOriginal(selection.baseOffset),
      extentOffset: _displayDocument.displayToOriginal(selection.extentOffset),
    );
    widget.onTextSelection(
      BookReaderSelectionResolver.resolve(
        selection: mappedSelection,
        globalStart: 0,
        localLength: _plainText.length,
        plainText: _plainText,
      ),
    );
  }

  void _clearSelection() {
    _selectionGeneration++;
    widget.onTextSelection(null);
  }
}
