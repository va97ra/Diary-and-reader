import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_import_parser.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('imports UTF-8 and UTF-16 plain text', () {
    final utf8Book = BookImportParser.parse(
      BookImportFile(
        name: 'notes.txt',
        bytes: Uint8List.fromList(utf8.encode('Первая строка\nВторая строка')),
      ),
    );
    final utf16Book = BookImportParser.parse(
      BookImportFile(name: 'wide.txt', bytes: _utf16Le('Текст UTF-16')),
    );

    expect(utf8Book.sourceFormat, 'TXT');
    expect(
      richDocumentPlainText(utf8Book.sections.single.content),
      contains('Вторая строка'),
    );
    expect(
      richDocumentPlainText(utf16Book.sections.single.content),
      contains('Текст UTF-16'),
    );
  });

  test('imports RTF paragraphs and Unicode escapes', () {
    final project = BookImportParser.parse(
      BookImportFile(
        name: 'sample.rtf',
        bytes: Uint8List.fromList(
          utf8.encode(r'{\rtf1\ansi Первая\par \u1042?торая}'),
        ),
      ),
    );

    final text = richDocumentPlainText(project.sections.single.content);
    expect(project.sourceFormat, 'RTF');
    expect(text, contains('Первая'));
    expect(text, contains('Вторая'));
  });

  test('imports DOCX text and core metadata', () {
    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          'word/document.xml',
          '<w:document xmlns:w="urn:w"><w:body>'
              '<w:p><w:r><w:t>Первый абзац</w:t></w:r></w:p>'
              '<w:p><w:r><w:t>Второй абзац</w:t></w:r></w:p>'
              '</w:body></w:document>',
        ),
      )
      ..addFile(
        ArchiveFile.string(
          'docProps/core.xml',
          '<cp:coreProperties xmlns:cp="urn:cp" xmlns:dc="urn:dc">'
              '<dc:title>Документ</dc:title><dc:creator>Автор</dc:creator>'
              '</cp:coreProperties>',
        ),
      );
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final project = BookImportParser.parse(
      BookImportFile(name: 'sample.docx', bytes: bytes),
    );

    expect(project.sourceFormat, 'DOCX');
    expect(project.metadata.title, 'Документ');
    expect(project.metadata.author, 'Автор');
    expect(
      richDocumentPlainText(project.sections.single.content),
      contains('Второй абзац'),
    );
  });

  test('imports unencrypted PalmDOC MOBI content', () {
    final project = BookImportParser.parse(
      BookImportFile(name: 'sample.mobi', bytes: _mobiFixture()),
    );

    expect(project.sourceFormat, 'MOBI');
    expect(project.metadata.title, 'Mobi Test');
    expect(
      richDocumentPlainText(project.sections.single.content),
      contains('Second paragraph'),
    );
  });
}

Uint8List _utf16Le(String value) {
  final output = BytesBuilder()..add([0xff, 0xfe]);
  for (final unit in value.codeUnits) {
    output.add([unit & 0xff, unit >> 8]);
  }
  return output.takeBytes();
}

Uint8List _mobiFixture() {
  final text = Uint8List.fromList(
    utf8.encode('<html><p>First paragraph</p><p>Second paragraph</p></html>'),
  );
  final record0 = Uint8List(140);
  final recordData = ByteData.sublistView(record0)
    ..setUint16(0, 1)
    ..setUint32(4, text.length)
    ..setUint16(8, 1)
    ..setUint16(10, 4096)
    ..setUint16(12, 0);
  record0.setRange(16, 20, ascii.encode('MOBI'));
  recordData
    ..setUint32(20, 116)
    ..setUint32(28, 65001)
    ..setUint32(100, 120)
    ..setUint32(104, 9);
  record0.setRange(120, 129, ascii.encode('Mobi Test'));

  const pdbHeaderLength = 94;
  final secondOffset = pdbHeaderLength + record0.length;
  final output = Uint8List(secondOffset + text.length);
  ByteData.sublistView(output)
    ..setUint16(76, 2)
    ..setUint32(78, pdbHeaderLength)
    ..setUint32(86, secondOffset);
  output
    ..setRange(pdbHeaderLength, secondOffset, record0)
    ..setRange(secondOffset, output.length, text);
  return output;
}
