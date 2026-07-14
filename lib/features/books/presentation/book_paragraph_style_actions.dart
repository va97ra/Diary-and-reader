import 'package:dnevnik/features/books/domain/book_paragraph_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

abstract final class BookParagraphStyleActions {
  static const semanticAttributeKey = 'bookParagraphStyle';

  static BookParagraphStyle current(QuillController controller) {
    final attributes = controller.getSelectionStyle().attributes;
    final semanticValue = attributes[semanticAttributeKey]?.value?.toString();
    final semanticStyle = BookParagraphStyle.values
        .where((style) => style.name == semanticValue)
        .firstOrNull;
    if (semanticStyle != null) return semanticStyle;

    final header = attributes[Attribute.header.key]?.value;
    if (header == 1) return BookParagraphStyle.heading1;
    if (header == 2) return BookParagraphStyle.heading2;
    if (header == 3) return BookParagraphStyle.heading3;
    if (attributes.containsKey(Attribute.blockQuote.key)) {
      return attributes[Attribute.align.key]?.value == 'right'
          ? BookParagraphStyle.epigraph
          : BookParagraphStyle.quote;
    }
    return BookParagraphStyle.body;
  }

  static void apply(QuillController controller, BookParagraphStyle style) {
    if (style == BookParagraphStyle.sceneBreak) {
      _insertSceneMarkerIntoEmptyLine(controller);
    }

    final selection = controller.selection;
    final length = selection.end - selection.start;
    for (final attribute in _clearedBlockAttributes) {
      controller.document.format(selection.start, length, attribute);
    }
    for (final attribute in _visualAttributes(style)) {
      controller.document.format(selection.start, length, attribute);
    }
    controller.document.format(
      selection.start,
      length,
      Attribute<String>(semanticAttributeKey, AttributeScope.block, style.name),
    );
    controller.updateSelection(controller.selection, ChangeSource.local);
  }

  static List<Attribute> get _clearedBlockAttributes => [
    Attribute.clone(Attribute.header, null),
    Attribute.clone(Attribute.blockQuote, null),
    Attribute.clone(Attribute.align, null),
    Attribute.clone(Attribute.list, null),
    Attribute.clone(Attribute.codeBlock, null),
    Attribute.clone(Attribute.indent, null),
    const Attribute<String?>(semanticAttributeKey, AttributeScope.block, null),
  ];

  static List<Attribute> _visualAttributes(BookParagraphStyle style) =>
      switch (style) {
        BookParagraphStyle.body => const [],
        BookParagraphStyle.heading1 => const [Attribute.h1],
        BookParagraphStyle.heading2 => const [Attribute.h2],
        BookParagraphStyle.heading3 => const [Attribute.h3],
        BookParagraphStyle.quote => const [Attribute.blockQuote],
        BookParagraphStyle.epigraph => const [
          Attribute.blockQuote,
          Attribute.rightAlignment,
        ],
        BookParagraphStyle.sceneBreak => const [Attribute.centerAlignment],
      };

  static void _insertSceneMarkerIntoEmptyLine(QuillController controller) {
    if (!controller.selection.isCollapsed) return;
    final text = controller.document.toPlainText();
    final offset = controller.selection.extentOffset.clamp(0, text.length - 1);
    final previousBreak = offset == 0 ? -1 : text.lastIndexOf('\n', offset - 1);
    final nextBreak = text.indexOf('\n', offset);
    final lineStart = previousBreak + 1;
    final lineEnd = nextBreak < 0 ? text.length : nextBreak;
    if (text.substring(lineStart, lineEnd).trim().isNotEmpty) return;

    const marker = '* * *';
    controller.document.replace(lineStart, lineEnd - lineStart, marker);
    controller.updateSelection(
      TextSelection.collapsed(offset: lineStart + marker.length),
      ChangeSource.local,
    );
  }
}
