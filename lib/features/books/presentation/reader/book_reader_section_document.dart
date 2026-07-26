part of 'book_reader_section_view.dart';

extension _BookReaderDocumentFlow on _BookReaderSectionViewState {
  List<BookReaderRenderHighlight> get _renderHighlights {
    if (widget.highlights.isEmpty) return const [];
    final plainText = richDocumentPlainText(widget.section.content);
    return [
      for (final highlight in widget.highlights)
        if (highlight.sectionId == widget.section.id)
          (() {
            final resolved = BookReaderTextAnchor.resolve(
              text: plainText,
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
    final plainText = richDocumentPlainText(widget.section.content);
    widget.onTextSelection(
      BookReaderSelectionResolver.resolve(
        selection: mappedSelection,
        globalStart: 0,
        localLength: plainText.length,
        plainText: plainText,
      ),
    );
  }

  void _clearSelection() {
    _selectionGeneration++;
    widget.onTextSelection(null);
  }
}
