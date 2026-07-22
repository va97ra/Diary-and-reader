import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_format_parser.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_import_parsing_support.dart';
import 'package:dnevnik/features/books/application/epub_book_format_parser.dart';
import 'package:dnevnik/features/books/application/fb2_book_format_parser.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';

abstract final class BookImportParser {
  static const List<BookFormatParser> _parsers = [
    EpubBookFormatParser(),
    Fb2BookFormatParser(),
  ];

  static BookProject parse(BookImportFile file, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    try {
      if (file.bytes.isEmpty || file.bytes.length > 256 * 1024 * 1024) {
        throw const BookImportException(BookImportFailure.invalidFile);
      }
      final format = _detect(file);
      final parser = _parsers
          .where((candidate) => candidate.formats.contains(format))
          .firstOrNull;
      if (parser == null) {
        throw const BookImportException(BookImportFailure.unsupportedFormat);
      }
      return parser.parse(file, timestamp, format);
    } on BookImportException {
      rethrow;
    } on Exception catch (error) {
      throw BookImportException(
        BookImportFailure.invalidFile,
        error.toString(),
      );
    }
  }

  static BookImportFormat _detect(BookImportFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.epub')) return BookImportFormat.epub;
    if (name.endsWith('.fb2')) return BookImportFormat.fb2;
    if (name.endsWith('.fb2.zip')) return BookImportFormat.fb2Zip;
    if (_isZip(file.bytes)) {
      final archive = ZipDecoder().decodeBytes(file.bytes);
      if (BookImportParsingSupport.archiveFile(
            archive,
            'META-INF/container.xml',
          ) !=
          null) {
        return BookImportFormat.epub;
      }
      if (archive.files.any(
        (entry) => entry.name.toLowerCase().endsWith('.fb2'),
      )) {
        return BookImportFormat.fb2Zip;
      }
    }
    final prefix = utf8.decode(
      file.bytes.take(512).toList(),
      allowMalformed: true,
    );
    if (prefix.contains('<FictionBook')) return BookImportFormat.fb2;
    throw const BookImportException(BookImportFailure.unsupportedFormat);
  }

  static bool _isZip(Uint8List bytes) =>
      bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4b;
}
