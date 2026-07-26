import 'dart:convert';

import 'package:dnevnik/features/books/domain/book_image_placement.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';

enum BookReaderBlockType {
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
  unsupportedEmbed,
}

enum BookReaderTextAlignment { left, center, right, justify }

class BookReaderTextRun {
  const BookReaderTextRun({
    required this.text,
    required this.sourceStart,
    required this.sourceEnd,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.superscript = false,
    this.subscript = false,
    this.link,
    this.fontFamily,
    this.fontSize,
    this.foregroundHex,
    this.backgroundHex,
  });

  final String text;
  final int sourceStart;
  final int sourceEnd;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;
  final bool superscript;
  final bool subscript;
  final String? link;
  final String? fontFamily;
  final double? fontSize;
  final String? foregroundHex;
  final String? backgroundHex;
}

class BookReaderBlock {
  const BookReaderBlock({
    required this.type,
    required this.runs,
    required this.sourceStart,
    required this.sourceEnd,
    this.alignment = BookReaderTextAlignment.left,
    this.indent = 0,
    this.lineHeight,
    this.rightToLeft = false,
    this.assetId,
    this.imageAlignment = BookImageAlignment.center,
    this.imageWidthPercent = 100,
    this.imageCaption = '',
    this.listOrdinal,
  });

  final BookReaderBlockType type;
  final List<BookReaderTextRun> runs;
  final int sourceStart;
  final int sourceEnd;
  final BookReaderTextAlignment alignment;
  final int indent;
  final double? lineHeight;
  final bool rightToLeft;
  final String? assetId;
  final BookImageAlignment imageAlignment;
  final int imageWidthPercent;
  final String imageCaption;
  final int? listOrdinal;

  String get text => runs.map((run) => run.text).join();

  bool get isText => switch (type) {
    BookReaderBlockType.image ||
    BookReaderBlockType.pageBreak ||
    BookReaderBlockType.unsupportedEmbed => false,
    _ => true,
  };
}

class BookReaderDocumentModel {
  const BookReaderDocumentModel({
    required this.blocks,
    required this.plainText,
    required this.sourceLength,
  });

  final List<BookReaderBlock> blocks;
  final String plainText;
  final int sourceLength;
}

abstract final class BookReaderDocumentParser {
  static BookReaderDocumentModel parse(RichDocument document) {
    final blocks = <BookReaderBlock>[];
    var runs = <BookReaderTextRun>[];
    var sourceOffset = 0;
    var skipEmbedNewline = false;
    var orderedListOrdinal = 0;

    void finishTextBlock(Map<String, dynamic> attributes) {
      final type = _blockType(attributes);
      if (type == BookReaderBlockType.orderedListItem) {
        orderedListOrdinal++;
      } else {
        orderedListOrdinal = 0;
      }
      final start = runs.isEmpty
          ? (sourceOffset - 1).clamp(0, sourceOffset)
          : runs.first.sourceStart;
      blocks.add(
        BookReaderBlock(
          type: type,
          runs: List.unmodifiable(runs),
          sourceStart: start,
          sourceEnd: sourceOffset,
          alignment: _alignment(attributes),
          indent: (_integer(attributes['indent']) ?? 0).clamp(0, 8),
          lineHeight: _lineHeight(attributes['line-height']),
          rightToLeft: attributes['direction'] == 'rtl',
          listOrdinal: type == BookReaderBlockType.orderedListItem
              ? orderedListOrdinal
              : null,
        ),
      );
      runs = <BookReaderTextRun>[];
    }

    for (final operation in document) {
      final insert = operation['insert'];
      if (insert is Map) {
        if (runs.isNotEmpty) finishTextBlock(const {});
        final block = _embedBlock(insert, sourceOffset);
        blocks.add(block);
        sourceOffset++;
        skipEmbedNewline = true;
        orderedListOrdinal = 0;
        continue;
      }
      if (insert is! String) continue;
      final attributes = operation['attributes'] is Map
          ? Map<String, dynamic>.from(operation['attributes'] as Map)
          : const <String, dynamic>{};
      var localStart = 0;
      while (localStart < insert.length) {
        final newline = insert.indexOf('\n', localStart);
        final localEnd = newline < 0 ? insert.length : newline;
        if (localEnd > localStart) {
          final text = insert.substring(localStart, localEnd);
          runs.add(
            _textRun(text, sourceStart: sourceOffset, attributes: attributes),
          );
          sourceOffset += text.length;
          skipEmbedNewline = false;
        }
        if (newline < 0) break;
        sourceOffset++;
        if (skipEmbedNewline && localEnd == localStart && runs.isEmpty) {
          skipEmbedNewline = false;
        } else {
          finishTextBlock(attributes);
        }
        localStart = newline + 1;
      }
    }
    if (runs.isNotEmpty) finishTextBlock(const {});
    if (blocks.isEmpty) {
      blocks.add(
        const BookReaderBlock(
          type: BookReaderBlockType.paragraph,
          runs: [],
          sourceStart: 0,
          sourceEnd: 0,
        ),
      );
    }
    return BookReaderDocumentModel(
      blocks: List.unmodifiable(blocks),
      plainText: richDocumentPlainText(document),
      sourceLength: sourceOffset,
    );
  }

  static BookReaderTextRun _textRun(
    String text, {
    required int sourceStart,
    required Map<String, dynamic> attributes,
  }) {
    final link = attributes['link']?.toString().trim();
    final font = attributes['font']?.toString().trim();
    return BookReaderTextRun(
      text: text,
      sourceStart: sourceStart,
      sourceEnd: sourceStart + text.length,
      bold: attributes['bold'] == true,
      italic: attributes['italic'] == true,
      underline: attributes['underline'] == true,
      strike: attributes['strike'] == true,
      code: attributes['code'] == true,
      superscript: attributes['script'] == 'super',
      subscript: attributes['script'] == 'sub',
      link: link != null && _safeLink(link) ? link : null,
      fontFamily: font == null || font.isEmpty ? null : font,
      fontSize: _fontSize(attributes['size']),
      foregroundHex: _color(attributes['color']),
      backgroundHex: _color(attributes['background']),
    );
  }

  static BookReaderBlock _embedBlock(Map insert, int sourceOffset) {
    if (_isPageBreak(insert)) {
      return BookReaderBlock(
        type: BookReaderBlockType.pageBreak,
        runs: const [],
        sourceStart: sourceOffset,
        sourceEnd: sourceOffset + 1,
      );
    }
    final image = _imagePlacement(insert);
    if (image != null) {
      return BookReaderBlock(
        type: BookReaderBlockType.image,
        runs: const [],
        sourceStart: sourceOffset,
        sourceEnd: sourceOffset + 1,
        assetId: image.assetId,
        imageAlignment: image.alignment,
        imageWidthPercent: image.widthPercent,
        imageCaption: image.caption,
      );
    }
    return BookReaderBlock(
      type: BookReaderBlockType.unsupportedEmbed,
      runs: const [],
      sourceStart: sourceOffset,
      sourceEnd: sourceOffset + 1,
    );
  }

  static BookReaderBlockType _blockType(Map<String, dynamic> attributes) {
    final list = attributes['list']?.toString();
    final header = _integer(attributes['header']);
    return switch (list) {
      'ordered' => BookReaderBlockType.orderedListItem,
      'bullet' => BookReaderBlockType.bulletListItem,
      'checked' => BookReaderBlockType.checkedListItem,
      'unchecked' => BookReaderBlockType.uncheckedListItem,
      _ when header == 1 => BookReaderBlockType.heading1,
      _ when header == 2 => BookReaderBlockType.heading2,
      _ when header == 3 => BookReaderBlockType.heading3,
      _ when attributes['blockquote'] == true => BookReaderBlockType.quote,
      _ when attributes['code-block'] == true => BookReaderBlockType.code,
      _ => BookReaderBlockType.paragraph,
    };
  }

  static BookReaderTextAlignment _alignment(Map<String, dynamic> attributes) =>
      switch (attributes['align']) {
        'center' => BookReaderTextAlignment.center,
        'right' => BookReaderTextAlignment.right,
        'justify' => BookReaderTextAlignment.justify,
        _ => BookReaderTextAlignment.left,
      };

  static double? _lineHeight(Object? value) {
    final parsed = double.tryParse(value?.toString() ?? '');
    return parsed != null && parsed >= 1 && parsed <= 3 ? parsed : null;
  }

  static double? _fontSize(Object? value) {
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null && parsed >= 6 && parsed <= 96) return parsed;
    return switch (value?.toString()) {
      'small' => 12,
      'large' => 24,
      'huge' => 32,
      _ => null,
    };
  }

  static String? _color(Object? value) {
    final color = value?.toString().trim();
    if (color == null || color.isEmpty) return null;
    return RegExp(r'^#?[0-9a-fA-F]{6,8}$').hasMatch(color) ? color : null;
  }

  static int? _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static bool _safeLink(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme.isEmpty ||
            const {'http', 'https', 'mailto'}.contains(uri.scheme));
  }

  static BookImagePlacement? _imagePlacement(Map insert) {
    final direct = insert['bookImage']?.toString();
    if (direct != null && direct.isNotEmpty) {
      return BookImagePlacement.decode(direct);
    }
    final custom = insert['custom'];
    if (custom is! String) return null;
    try {
      final decoded = jsonDecode(custom);
      if (decoded is! Map) return null;
      final value = decoded['bookImage']?.toString();
      return value == null || value.isEmpty
          ? null
          : BookImagePlacement.decode(value);
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
