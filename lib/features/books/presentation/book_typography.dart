import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

abstract final class BookTypography {
  static const titlePoints = 24.0;
  static const selectionTheme = TextSelectionThemeData(
    cursorColor: AppTheme.ink,
    selectionColor: Color(0x40334155),
    selectionHandleColor: AppTheme.ink,
  );

  static double get titleSize =>
      BookPageFormat.pointsToLogicalPixels(titlePoints);

  static DefaultStyles editorStyles(BookParagraphSettings settings) {
    final body = _textStyle(
      settings.fontSizePt,
      settings.lineHeight,
      fontFamily: settings.fontFamily,
    );
    // Quill draws a justified, centred or indented paragraph, or a list,
    // inside a block of its own kind, and spaces such lines by that kind.
    // Every kind spaces them as the book does, or they would stick together.
    final spacing = VerticalSpacing(
      BookPageFormat.pointsToLogicalPixels(settings.spacingBeforePt),
      BookPageFormat.pointsToLogicalPixels(settings.spacingAfterPt),
    );
    final paragraph = DefaultTextBlockStyle(
      body,
      HorizontalSpacing.zero,
      spacing,
      spacing,
      null,
    );
    return DefaultStyles(
      paragraph: paragraph,
      align: paragraph,
      indent: paragraph,
      lists: DefaultListBlockStyle(
        body,
        HorizontalSpacing.zero,
        spacing,
        spacing,
        null,
        null,
        indentWidthBuilder: _indentWidth,
      ),
      leading: paragraph,
      h1: _block(
        24,
        1.25,
        fontFamily: settings.fontFamily,
        weight: FontWeight.bold,
        top: 12,
        bottom: 6,
      ),
      h2: _block(
        18,
        1.3,
        fontFamily: settings.fontFamily,
        weight: FontWeight.bold,
        top: 10,
        bottom: 5,
      ),
      h3: _block(
        14,
        1.4,
        fontFamily: settings.fontFamily,
        weight: FontWeight.w600,
        top: 8,
        bottom: 4,
      ),
      quote: _block(
        settings.fontSizePt,
        settings.lineHeight,
        fontFamily: settings.fontFamily,
        fontStyle: FontStyle.italic,
        left: 20,
        right: 20,
        top: 8,
        bottom: 8,
      ),
      placeHolder: _block(
        settings.fontSizePt,
        settings.lineHeight,
        fontFamily: settings.fontFamily,
        color: const Color(0xFF94A3B8),
      ),
    );
  }

  /// Draws the first line of a body paragraph indented by the book's
  /// paragraph indent, as the exports do.
  ///
  /// Flutter lays a paragraph out without a first line indent, so the first
  /// character is drawn as a widget that holds the indent before it. It
  /// still stands for exactly one character, which keeps every offset of the
  /// line, the caret and the selection where Quill expects them.
  static TextSpanBuilder textSpanBuilder(BookParagraphSettings settings) {
    final indent = BookPageFormat.millimetersToLogicalPixels(
      settings.paragraphIndentMm,
    );
    final body = _textStyle(
      settings.fontSizePt,
      settings.lineHeight,
      fontFamily: settings.fontFamily,
    );
    return (context, node, textOffset, text, style, recognizer) {
      final line = node.parent;
      if (indent <= 0 ||
          textOffset != 0 ||
          node.offset != 0 ||
          line is! Line ||
          !indentsFirstLine(line.style.attributes) ||
          !_drawsAlone(text)) {
        return defaultSpanBuilder(
          context,
          node,
          textOffset,
          text,
          style,
          recognizer,
        );
      }
      final lineHeight = line.style.attributes[Attribute.lineHeight.key]?.value;
      final firstStyle = body
          .copyWith(height: lineHeight is num ? lineHeight.toDouble() : null)
          .merge(style);
      return TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            style: style,
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: indent),
              child: RichText(
                textScaler: MediaQuery.textScalerOf(context),
                text: TextSpan(
                  text: text[0],
                  style: firstStyle,
                  recognizer: recognizer,
                ),
              ),
            ),
          ),
          defaultSpanBuilder(
            context,
            node,
            textOffset + 1,
            text.substring(1),
            style,
            recognizer,
          ),
        ],
      );
    };
  }

  /// Whether a line with these attributes is body text whose first line
  /// takes the paragraph indent: not a heading, quote, poem or list, and
  /// neither centred nor set to the right.
  static bool indentsFirstLine(Map<String, Attribute<dynamic>> attributes) {
    if (attributes.containsKey(Attribute.header.key) ||
        attributes.containsKey(Attribute.blockQuote.key) ||
        attributes.containsKey(Attribute.codeBlock.key) ||
        attributes.containsKey(Attribute.list.key)) {
      return false;
    }
    final alignment = attributes[Attribute.align.key]?.value;
    return alignment == null || alignment == 'left' || alignment == 'justify';
  }

  /// Whether the first character can be drawn apart from the rest: a single
  /// code unit that no combining mark follows and that is not a line break.
  static bool _drawsAlone(String text) {
    if (text.isEmpty) return false;
    final first = text.codeUnitAt(0);
    if (first == 0x2028 || first == 0x0A || (first & 0xFC00) == 0xD800) {
      return false;
    }
    if (text.length == 1) return true;
    final next = text.codeUnitAt(1);
    return !(next >= 0x0300 && next <= 0x036F) &&
        !(next >= 0xFE00 && next <= 0xFE0F) &&
        next != 0x200D;
  }

  /// Quill indents a level by one size of the text; the book by
  /// [bookIndentLevelEm], so a level looks the same here and in the exports.
  static HorizontalSpacing _indentWidth(
    Block block,
    BuildContext context,
    int count,
    LeadingBlockNumberPointWidth numberPointWidth,
  ) {
    final quill = TextBlockUtils.defaultIndentWidthBuilder(
      block,
      context,
      count,
      numberPointWidth,
    );
    final level = block.style.attributes[Attribute.indent.key]?.value;
    if (level is! int || level <= 0) return quill;
    final fontSize =
        QuillStyles.getStyles(context, false)?.paragraph?.style.fontSize ?? 16;
    return HorizontalSpacing(
      quill.left + fontSize * (bookIndentLevelEm - 1) * level,
      quill.right,
    );
  }

  static TextStyle _textStyle(
    double points,
    double height, {
    required String fontFamily,
    FontWeight? weight,
    FontStyle? fontStyle,
    Color color = AppTheme.ink,
  }) => TextStyle(
    color: color,
    fontFamily: fontFamily,
    fontSize: BookPageFormat.pointsToLogicalPixels(points),
    height: height,
    fontWeight: weight,
    fontStyle: fontStyle,
    decoration: TextDecoration.none,
  );

  static DefaultTextBlockStyle _block(
    double points,
    double height, {
    required String fontFamily,
    FontWeight? weight,
    FontStyle? fontStyle,
    Color color = AppTheme.ink,
    double left = 0,
    double right = 0,
    double top = 0,
    double bottom = 0,
  }) => DefaultTextBlockStyle(
    _textStyle(
      points,
      height,
      fontFamily: fontFamily,
      weight: weight,
      fontStyle: fontStyle,
      color: color,
    ),
    HorizontalSpacing(left, right),
    VerticalSpacing(top, bottom),
    VerticalSpacing.zero,
    null,
  );
}
