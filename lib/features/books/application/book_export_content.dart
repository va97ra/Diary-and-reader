import 'dart:convert';

import 'package:dnevnik/features/books/domain/rich_document.dart';

enum BookExportBlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  quote,
  code,
  orderedListItem,
  bulletListItem,
  checkedListItem,
  uncheckedListItem,
  image,
  pageBreak,
}

enum BookExportTextAlignment { left, center, right, justify }

class BookExportTextRun {
  const BookExportTextRun({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.superscript = false,
    this.subscript = false,
    this.link,
    this.fontFamily,
    this.fontSizePt,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;
  final bool superscript;
  final bool subscript;
  final String? link;
  final String? fontFamily;
  final double? fontSizePt;
}

class BookExportBlock {
  const BookExportBlock({
    required this.type,
    required this.runs,
    this.alignment = BookExportTextAlignment.left,
    this.indent = 0,
    this.lineHeight,
    this.rightToLeft = false,
    this.semanticStyle,
    this.assetId,
  });

  final BookExportBlockType type;
  final List<BookExportTextRun> runs;
  final BookExportTextAlignment alignment;
  final int indent;
  final double? lineHeight;
  final bool rightToLeft;
  final String? semanticStyle;
  final String? assetId;

  bool get isListItem => switch (type) {
    BookExportBlockType.orderedListItem ||
    BookExportBlockType.bulletListItem ||
    BookExportBlockType.checkedListItem ||
    BookExportBlockType.uncheckedListItem => true,
    _ => false,
  };
}

abstract final class BookExportContentParser {
  static List<BookExportBlock> parse(RichDocument document) {
    final blocks = <BookExportBlock>[];
    var runs = <BookExportTextRun>[];
    var skipEmbedNewline = false;

    void finish(Map<String, dynamic> attributes) {
      blocks.add(_block(runs, attributes));
      runs = <BookExportTextRun>[];
    }

    for (final operation in document) {
      final insert = operation['insert'];
      if (insert is Map) {
        if (_isPageBreak(insert)) {
          if (runs.isNotEmpty) finish(const {});
          blocks.add(
            const BookExportBlock(
              type: BookExportBlockType.pageBreak,
              runs: [],
            ),
          );
          skipEmbedNewline = true;
          continue;
        }
        final assetId = _imageAssetId(insert);
        if (assetId != null) {
          if (runs.isNotEmpty) finish(const {});
          blocks.add(
            BookExportBlock(
              type: BookExportBlockType.image,
              runs: const [],
              assetId: assetId,
            ),
          );
          skipEmbedNewline = true;
        }
        continue;
      }
      if (insert is! String) continue;
      final attributes = operation['attributes'] is Map
          ? Map<String, dynamic>.from(operation['attributes'] as Map)
          : const <String, dynamic>{};
      final parts = insert.split('\n');
      for (var index = 0; index < parts.length; index++) {
        if (parts[index].isNotEmpty) {
          runs.add(_run(parts[index], attributes));
        }
        if (index < parts.length - 1) {
          if (skipEmbedNewline && parts[index].isEmpty) {
            skipEmbedNewline = false;
          } else {
            finish(attributes);
          }
        }
      }
    }
    if (runs.isNotEmpty) finish(const <String, dynamic>{});
    return blocks.isEmpty
        ? const [BookExportBlock(type: BookExportBlockType.paragraph, runs: [])]
        : blocks;
  }

  static BookExportTextRun _run(String text, Map<String, dynamic> attributes) {
    final link = attributes['link']?.toString().trim();
    final size = double.tryParse(attributes['size']?.toString() ?? '');
    final font = attributes['font']?.toString().trim();
    return BookExportTextRun(
      text: text,
      bold: attributes['bold'] == true,
      italic: attributes['italic'] == true,
      underline: attributes['underline'] == true,
      strike: attributes['strike'] == true,
      code: attributes['code'] == true,
      superscript: attributes['script'] == 'super',
      subscript: attributes['script'] == 'sub',
      link: link != null && _safeLink(link) ? link : null,
      fontFamily: font == null || font.isEmpty ? null : font,
      fontSizePt: size != null && size >= 6 && size <= 96 ? size * 0.75 : null,
    );
  }

  static BookExportBlock _block(
    List<BookExportTextRun> runs,
    Map<String, dynamic> attributes,
  ) {
    final list = attributes['list']?.toString();
    final header = _integer(attributes['header']);
    final type = switch (list) {
      'ordered' => BookExportBlockType.orderedListItem,
      'bullet' => BookExportBlockType.bulletListItem,
      'checked' => BookExportBlockType.checkedListItem,
      'unchecked' => BookExportBlockType.uncheckedListItem,
      _ when header == 1 => BookExportBlockType.heading1,
      _ when header == 2 => BookExportBlockType.heading2,
      _ when header == 3 => BookExportBlockType.heading3,
      _ when attributes['blockquote'] == true => BookExportBlockType.quote,
      _ when attributes['code-block'] == true => BookExportBlockType.code,
      _ => BookExportBlockType.paragraph,
    };
    final lineHeight = double.tryParse(
      attributes['line-height']?.toString() ?? '',
    );
    return BookExportBlock(
      type: type,
      runs: List.unmodifiable(runs),
      alignment: switch (attributes['align']) {
        'center' => BookExportTextAlignment.center,
        'right' => BookExportTextAlignment.right,
        'justify' => BookExportTextAlignment.justify,
        _ => BookExportTextAlignment.left,
      },
      indent: (_integer(attributes['indent']) ?? 0).clamp(0, 8),
      lineHeight: lineHeight != null && lineHeight >= 1 && lineHeight <= 3
          ? lineHeight
          : null,
      rightToLeft: attributes['direction'] == 'rtl',
      semanticStyle: attributes['bookParagraphStyle']?.toString(),
    );
  }

  static bool _safeLink(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme.isEmpty ||
            const {'http', 'https', 'mailto'}.contains(uri.scheme));
  }

  static int? _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static String? _imageAssetId(Map insert) {
    final direct = insert['bookImage']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final custom = insert['custom'];
    if (custom is! String) return null;
    try {
      final decoded = jsonDecode(custom);
      if (decoded is! Map) return null;
      final value = decoded['bookImage']?.toString();
      return value == null || value.isEmpty ? null : value;
    } on FormatException {
      return null;
    }
  }

  static bool _isPageBreak(Map insert) {
    if (insert['bookPageBreak'] != null) return true;
    final custom = insert['custom'];
    if (custom is! String) return false;
    try {
      final decoded = jsonDecode(custom);
      return decoded is Map && decoded['bookPageBreak'] != null;
    } on FormatException {
      return false;
    }
  }
}
