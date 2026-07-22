import 'dart:convert';
import 'dart:typed_data';

import 'package:dnevnik/features/books/application/book_format_parser.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_import_parsing_support.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';

class MobiBookFormatParser implements BookFormatParser {
  const MobiBookFormatParser();

  @override
  Set<BookImportFormat> get formats => const {BookImportFormat.mobi};

  @override
  BookProject parse(
    BookImportFile file,
    DateTime timestamp,
    BookImportFormat format,
  ) {
    final bytes = file.bytes;
    if (bytes.length < 100) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    final records = _recordOffsets(bytes);
    if (records.length < 2) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    final record0 = _record(bytes, records, 0);
    if (record0.length < 32) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    final header = ByteData.sublistView(record0);
    final compression = header.getUint16(0);
    final textLength = header.getUint32(4);
    final textRecordCount = header.getUint16(8);
    final encryption = header.getUint16(12);
    if (encryption != 0 || (compression != 1 && compression != 2)) {
      throw const BookImportException(BookImportFailure.unsupportedFormat);
    }
    final mobiOffset = _mobiOffset(record0);
    final encoding = mobiOffset == null || record0.length < mobiOffset + 16
        ? 65001
        : ByteData.sublistView(record0).getUint32(mobiOffset + 12);
    final title = _title(
      record0,
      mobiOffset,
      encoding,
      BookImportParsingSupport.baseName(file.name),
    );
    final output = <int>[];
    final count = textRecordCount.clamp(0, records.length - 1);
    for (var index = 1; index <= count; index++) {
      final record = _record(bytes, records, index);
      output.addAll(compression == 2 ? _decompressPalmDoc(record) : record);
      if (output.length >= textLength) break;
    }
    final contentBytes = Uint8List.fromList(
      output.take(textLength.clamp(0, output.length)).toList(),
    );
    final source = _decode(contentBytes, encoding);
    final plainText = _htmlToText(source);
    if (plainText.isEmpty) {
      throw const BookImportException(BookImportFailure.noReadableText);
    }
    final section =
        BookSection.create(
          id: 'imported-${timestamp.microsecondsSinceEpoch}-section-1',
          title: title,
          type: BookSectionType.chapter,
          now: timestamp,
        ).copyWith(
          content: [
            {'insert': '$plainText\n'},
          ],
          status: DraftStatus.complete,
        );
    return BookImportParsingSupport.project(
      file: file,
      timestamp: timestamp,
      sourceFormat: 'MOBI',
      metadata: BookMetadata(title: title),
      sections: [section],
    );
  }

  List<int> _recordOffsets(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final count = data.getUint16(76);
    if (78 + count * 8 > bytes.length) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    return [
      for (var index = 0; index < count; index++)
        data.getUint32(78 + index * 8),
    ];
  }

  Uint8List _record(Uint8List bytes, List<int> offsets, int index) {
    final start = offsets[index];
    final end = index + 1 < offsets.length ? offsets[index + 1] : bytes.length;
    if (start < 0 || end <= start || end > bytes.length) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    return Uint8List.sublistView(bytes, start, end);
  }

  int? _mobiOffset(Uint8List record0) {
    for (var index = 16; index + 4 <= record0.length; index++) {
      if (record0[index] == 0x4d &&
          record0[index + 1] == 0x4f &&
          record0[index + 2] == 0x42 &&
          record0[index + 3] == 0x49) {
        return index;
      }
    }
    return null;
  }

  String _title(
    Uint8List record0,
    int? mobiOffset,
    int encoding,
    String fallback,
  ) {
    if (mobiOffset == null || record0.length < mobiOffset + 92) return fallback;
    final data = ByteData.sublistView(record0);
    final offset = data.getUint32(mobiOffset + 84);
    final length = data.getUint32(mobiOffset + 88);
    if (offset < 0 || length <= 0 || offset + length > record0.length) {
      return fallback;
    }
    return _decode(
      Uint8List.sublistView(record0, offset, offset + length),
      encoding,
    ).trim().ifEmpty(fallback);
  }

  List<int> _decompressPalmDoc(Uint8List input) {
    final output = <int>[];
    var index = 0;
    while (index < input.length) {
      final value = input[index++];
      if (value == 0) {
        output.add(0);
      } else if (value <= 8) {
        final count = value.clamp(0, input.length - index);
        output.addAll(input.sublist(index, index + count));
        index += count;
      } else if (value <= 0x7f) {
        output.add(value);
      } else if (value <= 0xbf) {
        if (index >= input.length) break;
        final next = input[index++];
        final pair = (value << 8) | next;
        final distance = (pair >> 3) & 0x7ff;
        final length = (pair & 7) + 3;
        if (distance <= 0 || distance > output.length) {
          throw const BookImportException(BookImportFailure.invalidFile);
        }
        for (var copied = 0; copied < length; copied++) {
          output.add(output[output.length - distance]);
        }
      } else {
        output
          ..add(0x20)
          ..add(value ^ 0x80);
      }
    }
    return output;
  }

  String _decode(Uint8List bytes, int encoding) {
    if (encoding == 65001) return utf8.decode(bytes, allowMalformed: true);
    return latin1.decode(bytes, allowInvalid: true);
  }

  String _htmlToText(String source) {
    var value = source
        .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
        .replaceAll(
          RegExp(
            r'</\s*(p|div|h[1-6]|li|blockquote)\s*>',
            caseSensitive: false,
          ),
          '\n\n',
        )
        .replaceAll(RegExp('<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    value = value.replaceAllMapped(RegExp(r'&#(x?[0-9a-fA-F]+);'), (match) {
      final raw = match.group(1)!;
      final code = raw.startsWith('x')
          ? int.tryParse(raw.substring(1), radix: 16)
          : int.tryParse(raw);
      return code == null ? '' : String.fromCharCode(code);
    });
    return value
        .replaceAll('\u0000', '')
        .replaceAll('\r', '')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
