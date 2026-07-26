part of 'book_reader_section_view.dart';

extension _BookReaderDocumentFlow on _BookReaderSectionViewState {
  void _selectSpeechTarget({
    required int displayOffset,
    required int displayStart,
  }) {
    final plainText = richDocumentPlainText(widget.section.content);
    final originalOffset = _displayDocument.displayToOriginal(
      displayStart + displayOffset,
    );
    widget.onSpeechTargetSelected(originalOffset.clamp(0, plainText.length));
  }

  QuillController _pageController(RichDocument document, int displayStart) =>
      QuillController(
        document: _readerDocument(document, displayStart: displayStart),
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
        onSelectionChanged: (selection) =>
            _handleTextSelection(selection, displayStart: displayStart),
      );

  Document _readerDocument(RichDocument source, {required int displayStart}) {
    final document = Document.fromJson(source);
    if (widget.settings.justifyText && document.length > 1) {
      document.format(0, document.length - 1, Attribute.justifyAlignment);
    }
    final localLength = _selectableLength(source);
    final fullText = richDocumentPlainText(widget.section.content);
    for (final highlight in widget.highlights) {
      final range = BookReaderTextAnchor.resolve(
        text: fullText,
        startOffset: highlight.startOffset,
        endOffset: highlight.endOffset,
        excerpt: highlight.excerpt,
        sectionProgress: highlight.sectionProgress,
      );
      final start = math.max(
        0,
        _displayDocument.originalToDisplay(range.start) - displayStart,
      );
      final end = math.min(
        localLength,
        _displayDocument.originalToDisplay(range.end) - displayStart,
      );
      if (end <= start) continue;
      document.format(
        start,
        end - start,
        BackgroundAttribute(
          BookReaderHighlightStyle.backgroundHex(
            highlight.color,
            widget.palette,
          ),
        ),
      );
    }
    if (widget.speechRange case final speechRange?) {
      final start = math.max(
        0,
        _displayDocument.originalToDisplay(speechRange.start) - displayStart,
      );
      final end = math.min(
        localLength,
        _displayDocument.originalToDisplay(speechRange.end) - displayStart,
      );
      if (end > start) {
        document.format(
          start,
          end - start,
          BackgroundAttribute(
            BookReaderHighlightStyle.backgroundHex(
              BookReaderHighlightColor.blue,
              widget.palette,
            ),
          ),
        );
      }
    }
    return document;
  }

  void _handleTextSelection(
    TextSelection selection, {
    required int displayStart,
  }) {
    final plainText = richDocumentPlainText(widget.section.content);
    final mappedSelection = TextSelection(
      baseOffset: _displayDocument.displayToOriginal(
        displayStart + selection.baseOffset,
      ),
      extentOffset: _displayDocument.displayToOriginal(
        displayStart + selection.extentOffset,
      ),
    );
    if (widget.speechTargetMode && mappedSelection.isCollapsed) {
      widget.onSpeechTargetSelected(
        mappedSelection.extentOffset.clamp(0, plainText.length),
      );
      return;
    }
    final resolved = BookReaderSelectionResolver.resolve(
      selection: mappedSelection,
      globalStart: 0,
      localLength: plainText.length,
      plainText: plainText,
    );
    if (resolved != null) widget.onTextSelection(resolved);
  }

  void _replaceVisiblePagesForHighlights() {
    if (_pageDocuments.isEmpty || _pageStartOffsets.isEmpty) return;
    _disposePageResourcesAfterFrame(_takePageResources());
  }

  int _selectableLength(RichDocument document) {
    final length = _documentContentLength(document);
    return document.lastOrNull?['insert'] == '\n'
        ? math.max(0, length - 1)
        : length;
  }

  void _clearSelection() {
    final controllers = [
      _continuousController,
      ..._pageResources.values.map((resources) => resources.controller),
    ];
    for (final controller in controllers) {
      final selection = controller.selection;
      if (selection.isCollapsed) continue;
      controller.updateSelection(
        TextSelection.collapsed(offset: selection.extentOffset),
        ChangeSource.local,
      );
    }
    _continuousFocusNode.unfocus();
    for (final resources in _pageResources.values) {
      resources.focusNode.unfocus();
    }
    widget.onTextSelection(null);
  }
}
