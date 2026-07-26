import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_document_model.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:flutter/material.dart';

class BookReaderBlockTypography {
  const BookReaderBlockTypography({
    required this.textStyle,
    required this.textAlign,
    required this.textDirection,
    required this.topSpacing,
    required this.bottomSpacing,
    required this.leftInset,
    required this.rightInset,
    required this.prefix,
  });

  final TextStyle textStyle;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final double topSpacing;
  final double bottomSpacing;
  final double leftInset;
  final double rightInset;
  final String prefix;
}

abstract final class BookReaderTypography {
  static BookReaderBlockTypography block(
    BookReaderBlock block,
    BookReaderSettings settings,
    BookReaderPalette palette,
  ) {
    final baseWeight = _fontWeight(settings.fontWeight);
    var size = settings.fontSize;
    var height = block.lineHeight ?? settings.lineHeight;
    var weight = baseWeight;
    var style = FontStyle.normal;
    var color = palette.ink;
    var top = 0.0;
    var bottom = settings.fontSize * 0.45;
    var left = block.indent * settings.fontSize * 1.35;
    var right = 0.0;
    var prefix = '';
    var family = settings.fontFamily;

    switch (block.type) {
      case BookReaderBlockType.heading1:
        size *= 1.65;
        height = 1.25;
        weight = FontWeight.bold;
        top = 22;
        bottom = 12;
      case BookReaderBlockType.heading2:
        size *= 1.35;
        height = 1.3;
        weight = FontWeight.bold;
        top = 18;
        bottom = 10;
      case BookReaderBlockType.heading3:
        size *= 1.15;
        height = 1.35;
        weight = FontWeight.w600;
        top = 14;
        bottom = 8;
      case BookReaderBlockType.quote:
        style = FontStyle.italic;
        color = palette.mutedInk;
        left += 24;
        right = 16;
        top = 10;
        bottom = 10;
      case BookReaderBlockType.code:
        family = 'monospace';
        size *= 0.92;
        height = 1.45;
        left += 12;
        right = 12;
        top = 8;
        bottom = 8;
      case BookReaderBlockType.orderedListItem:
        prefix = '${block.listOrdinal ?? 1}. ';
        left += settings.fontSize * 1.2;
      case BookReaderBlockType.bulletListItem:
        prefix = '• ';
        left += settings.fontSize * 1.2;
      case BookReaderBlockType.checkedListItem:
        prefix = '☑ ';
        left += settings.fontSize * 1.2;
      case BookReaderBlockType.uncheckedListItem:
        prefix = '☐ ';
        left += settings.fontSize * 1.2;
      case BookReaderBlockType.paragraph:
      case BookReaderBlockType.image:
      case BookReaderBlockType.pageBreak:
      case BookReaderBlockType.unsupportedEmbed:
        break;
    }

    final requestedAlignment = switch (block.alignment) {
      BookReaderTextAlignment.center => TextAlign.center,
      BookReaderTextAlignment.right => TextAlign.right,
      BookReaderTextAlignment.justify => TextAlign.justify,
      BookReaderTextAlignment.left => TextAlign.left,
    };
    final alignment =
        settings.justifyText &&
            block.alignment == BookReaderTextAlignment.left &&
            block.type == BookReaderBlockType.paragraph
        ? TextAlign.justify
        : requestedAlignment;
    return BookReaderBlockTypography(
      textStyle: TextStyle(
        color: color,
        fontFamily: family,
        fontSize: size,
        height: height,
        fontWeight: weight,
        fontStyle: style,
        decoration: TextDecoration.none,
      ),
      textAlign: alignment,
      textDirection: block.rightToLeft ? TextDirection.rtl : TextDirection.ltr,
      topSpacing: top,
      bottomSpacing: bottom,
      leftInset: left,
      rightInset: right,
      prefix: prefix,
    );
  }

  static TextStyle run(
    BookReaderTextRun run,
    TextStyle baseStyle, {
    Color? backgroundColor,
  }) {
    final decorations = <TextDecoration>[
      if (run.underline) TextDecoration.underline,
      if (run.strike) TextDecoration.lineThrough,
    ];
    final scripted = run.superscript || run.subscript;
    return baseStyle.copyWith(
      color: _color(run.foregroundHex) ?? baseStyle.color,
      backgroundColor:
          backgroundColor ??
          _color(run.backgroundHex) ??
          baseStyle.backgroundColor,
      fontFamily: run.code
          ? 'monospace'
          : run.fontFamily ?? baseStyle.fontFamily,
      fontSize: scripted
          ? (run.fontSize ?? baseStyle.fontSize ?? 16) * 0.76
          : run.fontSize ?? baseStyle.fontSize,
      fontWeight: run.bold ? FontWeight.bold : baseStyle.fontWeight,
      fontStyle: run.italic ? FontStyle.italic : baseStyle.fontStyle,
      decoration: decorations.isEmpty
          ? baseStyle.decoration
          : TextDecoration.combine(decorations),
      decorationColor: baseStyle.color,
    );
  }

  static Color? color(String? value) => _color(value);

  static FontWeight _fontWeight(double value) => switch (value.round()) {
    <= 300 => FontWeight.w300,
    <= 400 => FontWeight.w400,
    <= 500 => FontWeight.w500,
    <= 600 => FontWeight.w600,
    _ => FontWeight.w700,
  };

  static Color? _color(String? value) {
    if (value == null) return null;
    final normalized = value.replaceFirst('#', '');
    if (normalized.length != 6 && normalized.length != 8) return null;
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return null;
    return Color(normalized.length == 6 ? 0xFF000000 | parsed : parsed);
  }
}
