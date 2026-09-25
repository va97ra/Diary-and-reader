import 'package:dnevnik/features/books/domain/book_paragraph_style.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
// flutter_quill is pinned, so its rules are stable for this app.
// ignore: experimental_member_use
import 'package:flutter_quill/internal.dart' show AutoExitBlockRule, InsertRule;
import 'package:flutter_quill/quill_delta.dart';

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

  /// Whether [style], by its name in a document, is drawn as a quote block.
  static bool _isQuoteBlock(Object? style) => BookParagraphStyle.values.any(
    (value) =>
        value.name == style &&
        _visualAttributes(value).contains(Attribute.blockQuote),
  );

  /// Gives the quote mark back to lines of a quote, an epigraph or a poem
  /// that lost it while keeping the style's name, as Enter on an empty line
  /// used to do. The editor drew them as plain text while the reader and the
  /// exports still saw a poem.
  static RichDocument repairQuoteBlocks(RichDocument document) {
    bool broken(Map<String, dynamic> operation) {
      final insert = operation['insert'];
      final attributes = operation['attributes'];
      return insert is String &&
          insert.contains('\n') &&
          attributes is Map &&
          _isQuoteBlock(attributes[semanticAttributeKey]) &&
          attributes[Attribute.blockQuote.key] != true;
    }

    if (!document.any(broken)) return document;
    return [
      for (final operation in document)
        if (broken(operation))
          {
            ...operation,
            'attributes': {
              ...operation['attributes'] as Map,
              Attribute.blockQuote.key: true,
            },
          }
        else
          operation,
    ];
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
        // A quote block keeps the lines of a stanza together without
        // paragraph spacing; centring sets it apart from quotes.
        BookParagraphStyle.verse => const [
          Attribute.blockQuote,
          Attribute.centerAlignment,
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

/// Enter on an empty line at the end of a quote, an epigraph or a poem.
///
/// Quill leaves the block by dropping only the quote mark, which kept the
/// style's name and alignment on the line: the editor showed plain text
/// where the reader and the exports saw a poem. Here one empty line in a
/// poem separates stanzas and the poem goes on; Enter on a second empty line,
/// or on an empty line of a quote, turns the line into body text.
class BookQuoteBlockExitRule extends InsertRule {
  const BookQuoteBlockExitRule();

  @override
  Delta? applyRule(
    Document document,
    int index, {
    int? len,
    Object? data,
    Attribute? attribute,
  }) {
    // Quill decides whether this Enter leaves the block.
    if (const AutoExitBlockRule().applyRule(
          document,
          index,
          len: len,
          data: data,
          attribute: attribute,
        ) ==
        null) {
      return null;
    }
    final line = (DeltaIterator(
      document.toDelta(),
    )..skip(index)).next().attributes;
    final style = line?[BookParagraphStyleActions.semanticAttributeKey];
    if (line == null || !BookParagraphStyleActions._isQuoteBlock(style)) {
      return null;
    }
    final text = document.toPlainText();
    final afterEmptyLine = index < 2 || text[index - 2] == '\n';
    final at = index + (len ?? 0);
    if (style == BookParagraphStyle.verse.name && !afterEmptyLine) {
      return Delta()
        ..retain(at)
        ..insert('\n', line);
    }
    return Delta()
      ..retain(at)
      ..retain(1, {for (final key in line.keys) key: null});
  }
}
