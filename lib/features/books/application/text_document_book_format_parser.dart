import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_format_parser.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_import_parsing_support.dart';
import 'package:dnevnik/features/books/application/xml_text_decoder.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_plain_text_chunk.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:xml/xml.dart';

class TextDocumentBookFormatParser implements BookFormatParser {
  const TextDocumentBookFormatParser();

  @override
  Set<BookImportFormat> get formats => const {
    BookImportFormat.txt,
    BookImportFormat.rtf,
    BookImportFormat.docx,
  };

  @override
  BookProject parse(
    BookImportFile file,
    DateTime timestamp,
    BookImportFormat format,
  ) => switch (format) {
    BookImportFormat.txt => _textProject(
      file,
      timestamp,
      sourceFormat: 'TXT',
      text: _decodeText(file.bytes),
    ),
    BookImportFormat.rtf => _textProject(
      file,
      timestamp,
      sourceFormat: 'RTF',
      text: _decodeRtf(_decodeText(file.bytes)),
    ),
    BookImportFormat.docx => _parseDocx(file, timestamp),
    _ => throw const BookImportException(BookImportFailure.unsupportedFormat),
  };

  BookProject parseCatalog(
    BookImportFile file,
    DateTime timestamp,
    BookImportFormat format,
  ) {
    final metadata = switch (format) {
      BookImportFormat.docx => _catalogDocxMetadata(file),
      BookImportFormat.txt || BookImportFormat.rtf => BookMetadata(
        title: BookImportParsingSupport.baseName(file.name),
      ),
      _ => throw const BookImportException(BookImportFailure.unsupportedFormat),
    };
    if (format == BookImportFormat.rtf) {
      final prefix = utf8.decode(
        file.bytes.take(32).toList(),
        allowMalformed: true,
      );
      if (!prefix.trimLeft().startsWith(r'{\rtf')) {
        throw const BookImportException(BookImportFailure.invalidFile);
      }
    }
    if (format == BookImportFormat.txt &&
        utf8
            .decode(file.bytes.take(4096).toList(), allowMalformed: true)
            .trim()
            .isEmpty) {
      throw const BookImportException(BookImportFailure.noReadableText);
    }
    return BookImportParsingSupport.catalogProject(
      file: file,
      timestamp: timestamp,
      sourceFormat: format.name.toUpperCase(),
      metadata: metadata,
    );
  }

  BookMetadata _catalogDocxMetadata(BookImportFile file) {
    final archive = ZipDecoder().decodeBytes(file.bytes);
    if (BookImportParsingSupport.archiveFile(archive, 'word/document.xml') ==
        null) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    return _docxMetadata(archive, file.name);
  }

  BookProject _parseDocx(BookImportFile file, DateTime timestamp) {
    final archive = ZipDecoder().decodeBytes(file.bytes);
    final documentEntry = BookImportParsingSupport.archiveFile(
      archive,
      'word/document.xml',
    );
    if (documentEntry == null) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    final document = XmlDocument.parse(
      XmlTextDecoder.decode(
        BookImportParsingSupport.archiveBytes(documentEntry),
      ),
    );
    final paragraphs = document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'p')
        .map(_docxParagraphText)
        .where((text) => text.trim().isNotEmpty)
        .toList();
    final metadata = _docxMetadata(archive, file.name);
    return _textProject(
      file,
      timestamp,
      sourceFormat: 'DOCX',
      text: paragraphs.join('\n\n'),
      metadata: metadata,
    );
  }

  String _docxParagraphText(XmlElement paragraph) {
    final buffer = StringBuffer();
    for (final node in paragraph.descendants.whereType<XmlElement>()) {
      switch (node.name.local) {
        case 't':
          buffer.write(node.innerText);
        case 'tab':
          buffer.write('\t');
        case 'br' || 'cr':
          buffer.write('\n');
      }
    }
    return buffer.toString().trimRight();
  }

  BookMetadata _docxMetadata(Archive archive, String fileName) {
    final entry = BookImportParsingSupport.archiveFile(
      archive,
      'docProps/core.xml',
    );
    if (entry == null) {
      return BookMetadata(title: BookImportParsingSupport.baseName(fileName));
    }
    final document = XmlDocument.parse(
      XmlTextDecoder.decode(BookImportParsingSupport.archiveBytes(entry)),
    );
    String value(String name) =>
        document.descendants
            .whereType<XmlElement>()
            .where((element) => element.name.local == name)
            .map((element) => element.innerText.trim())
            .where((text) => text.isNotEmpty)
            .firstOrNull ??
        '';
    return BookMetadata(
      title: value(
        'title',
      ).ifEmpty(BookImportParsingSupport.baseName(fileName)),
      author: value('creator'),
      description: value('description'),
      languageCode: BookImportParsingSupport.language(value('language')),
    );
  }

  BookProject _textProject(
    BookImportFile file,
    DateTime timestamp, {
    required String sourceFormat,
    required String text,
    BookMetadata? metadata,
  }) {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{4,}'), '\n\n\n')
        .trim();
    if (normalized.isEmpty) {
      throw const BookImportException(BookImportFailure.noReadableText);
    }
    final title =
        metadata?.title ?? BookImportParsingSupport.baseName(file.name);
    final baseId = 'imported-${timestamp.microsecondsSinceEpoch}-section-1';
    final chunks = BookPlainTextChunker.split(normalized);
    final sections = [
      for (var index = 0; index < chunks.length; index++)
        BookSection.create(
          id: index == 0 ? baseId : '$baseId-part-${index + 1}',
          title:
              chunks[index].heading ??
              (index == 0 ? title : '$title — ${index + 1}'),
          type: BookSectionType.chapter,
          now: timestamp,
        ).copyWith(
          content: [
            {
              'insert': chunks[index].text.endsWith('\n')
                  ? chunks[index].text
                  : '${chunks[index].text}\n',
            },
          ],
          status: DraftStatus.complete,
        ),
    ];
    return BookImportParsingSupport.project(
      file: file,
      timestamp: timestamp,
      sourceFormat: sourceFormat,
      metadata: metadata ?? BookMetadata(title: title),
      sections: sections,
    );
  }

  String _decodeText(Uint8List bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xfe) {
      return _decodeUtf16(bytes.sublist(2), littleEndian: true);
    }
    if (bytes.length >= 2 && bytes[0] == 0xfe && bytes[1] == 0xff) {
      return _decodeUtf16(bytes.sublist(2), littleEndian: false);
    }
    return utf8.decode(bytes, allowMalformed: true).replaceFirst('\ufeff', '');
  }

  String _decodeUtf16(Uint8List bytes, {required bool littleEndian}) {
    final units = <int>[];
    for (var index = 0; index + 1 < bytes.length; index += 2) {
      units.add(
        littleEndian
            ? bytes[index] | (bytes[index + 1] << 8)
            : (bytes[index] << 8) | bytes[index + 1],
      );
    }
    return String.fromCharCodes(units);
  }

  String _decodeRtf(String source) {
    if (!source.trimLeft().startsWith(r'{\rtf')) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    var value = source;
    value = value.replaceAllMapped(RegExp(r'\\u(-?\d+)\??'), (match) {
      var code = int.parse(match.group(1)!);
      if (code < 0) code += 65536;
      return String.fromCharCode(code);
    });
    value = value.replaceAllMapped(
      RegExp(r"\\'([0-9a-fA-F]{2})"),
      (match) => String.fromCharCode(int.parse(match.group(1)!, radix: 16)),
    );
    value = value
        .replaceAll(RegExp(r'\\par[d]?\b ?'), '\n')
        .replaceAll(RegExp(r'\\tab\b ?'), '\t')
        .replaceAll(RegExp(r'\\[a-zA-Z]+-?\d* ?'), '')
        .replaceAll(r'\{', '{')
        .replaceAll(r'\}', '}')
        .replaceAll(r'\\', r'\')
        .replaceAll(RegExp(r'[{}]'), '');
    return value;
  }
}
