import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dnevnik/features/books/application/book_epub_exporter.dart';
import 'package:dnevnik/features/books/application/book_fb2_exporter.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_import_parser.dart';
import 'package:dnevnik/features/books/application/xml_book_content_converter.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  group('BookImportParser', () {
    test('imports the representative FB2 fixture used for visual checks', () {
      final fixture = File('test/fixtures/import_sample.fb2').readAsBytesSync();

      final imported = BookImportParser.parse(
        BookImportFile(name: 'import_sample.fb2', bytes: fixture),
        now: _importTime,
      );

      expect(imported.metadata.title, 'Книга для проверки импорта');
      expect(imported.metadata.author, 'Тестовый Автор');
      expect(imported.sections, hasLength(2));
      expect(imported.sections.first.title, 'Глава первая');
      expect(imported.sections.last.title, 'Глава вторая');
    });

    test('imports an exported FB2 as a read-only book with rich text', () {
      final source = _sourceProject();
      final exported = BookFb2Exporter.create(source);

      final imported = BookImportParser.parse(
        BookImportFile(name: 'роман.fb2', bytes: exported.bytes),
        now: _importTime,
      );

      expect(imported.kind, BookProjectKind.importedBook);
      expect(imported.isReadOnly, isTrue);
      expect(imported.sourceFormat, 'FB2');
      expect(imported.sourceFileName, 'роман.fb2');
      expect(imported.metadata.title, source.metadata.title);
      expect(imported.metadata.author, source.metadata.author);
      expect(imported.sections, isNotEmpty);
      expect(
        imported.sections.map((section) => section.title),
        containsAll(['Часть первая', 'Глава первая']),
      );
      expect(
        imported.sections
            .map((section) => richDocumentPlainText(section.content))
            .join(),
        contains('Жирный текст'),
      );
      expect(
        imported.sections
            .expand((section) => section.content)
            .any(
              (operation) => (operation['attributes'] as Map?)?['bold'] == true,
            ),
        isTrue,
      );
    });

    test('imports FB2.ZIP and restores the archived source format', () {
      final exported = BookFb2Exporter.createZip(_sourceProject());

      final imported = BookImportParser.parse(
        BookImportFile(name: 'роман.fb2.zip', bytes: exported.bytes),
        now: _importTime,
      );

      expect(imported.sourceFormat, 'FB2.ZIP');
      expect(imported.metadata.title, 'Книга & море');
      expect(imported.sections, isNotEmpty);
    });

    test('decodes legacy Windows-1251 FB2 files', () {
      const xml = '''<?xml version="1.0" encoding="windows-1251"?>
<FictionBook><description><title-info><book-title>Ёжик в тумане</book-title><lang>ru</lang></title-info></description><body><section><title><p>Глава</p></title><p>Русский текст</p></section></body></FictionBook>''';

      final imported = BookImportParser.parse(
        BookImportFile(name: 'legacy.fb2', bytes: _windows1251(xml)),
        now: _importTime,
      );

      expect(imported.metadata.title, 'Ёжик в тумане');
      expect(
        richDocumentPlainText(imported.sections.single.content),
        contains('Русский текст'),
      );
    });

    test('imports EPUB metadata and spine content in reading order', () {
      final exported = BookEpubExporter.create(_sourceProject());

      final imported = BookImportParser.parse(
        BookImportFile(name: 'novel.epub', bytes: exported.bytes),
        now: _importTime,
      );

      expect(imported.kind, BookProjectKind.importedBook);
      expect(imported.sourceFormat, 'EPUB');
      expect(imported.metadata.title, 'Книга & море');
      expect(imported.metadata.author, 'Иван Тестов');
      expect(imported.sections.length, greaterThanOrEqualTo(2));
      expect(
        imported.sections
            .map((section) => richDocumentPlainText(section.content))
            .join(),
        contains('Жирный текст'),
      );
    });

    test('rejects unsupported and textless book files with clear reasons', () {
      expect(
        () => BookImportParser.parse(
          BookImportFile(
            name: 'book.pdf',
            bytes: Uint8List.fromList(utf8.encode('%PDF')),
          ),
        ),
        throwsA(
          isA<BookImportException>().having(
            (error) => error.failure,
            'failure',
            BookImportFailure.unsupportedFormat,
          ),
        ),
      );
      expect(
        () => BookImportParser.parse(
          BookImportFile(
            name: 'empty.fb2',
            bytes: Uint8List.fromList(
              utf8.encode(
                '<?xml version="1.0"?><FictionBook><description><title-info><book-title>Пусто</book-title></title-info></description><body/></FictionBook>',
              ),
            ),
          ),
        ),
        throwsA(
          isA<BookImportException>().having(
            (error) => error.failure,
            'failure',
            BookImportFailure.noReadableText,
          ),
        ),
      );
    });

    test('persists imported-book identity through project serialization', () {
      final imported = BookImportParser.parse(
        BookImportFile(
          name: 'book.fb2',
          bytes: BookFb2Exporter.create(_sourceProject()).bytes,
        ),
        now: _importTime,
      );

      final restored = BookProject.fromJson(imported.toJson());

      expect(restored.kind, BookProjectKind.importedBook);
      expect(restored.sourceFormat, 'FB2');
      expect(restored.sourceFileName, 'book.fb2');
      expect(restored.readerProgress.sectionId, restored.sections.first.id);
    });

    test('ignores scripts and unsafe links in imported markup', () {
      final body = XmlDocument.parse(
        '<body><script>bad code</script><p><a href="javascript:bad">Безопасный текст</a></p></body>',
      ).rootElement;

      final content = XmlBookContentConverter.convert(body.children);

      expect(richDocumentPlainText(content), contains('Безопасный текст'));
      expect(richDocumentPlainText(content), isNot(contains('bad code')));
      expect(
        content.any(
          (operation) =>
              (operation['attributes'] as Map?)?.containsKey('link') ?? false,
        ),
        isFalse,
      );
    });
  });
}

Uint8List _windows1251(String value) => Uint8List.fromList(
  value.runes.map((codePoint) {
    if (codePoint < 0x80) return codePoint;
    if (codePoint == 0x0401) return 0xa8;
    if (codePoint == 0x0451) return 0xb8;
    if (codePoint >= 0x0410 && codePoint <= 0x042f) {
      return 0xc0 + codePoint - 0x0410;
    }
    if (codePoint >= 0x0430 && codePoint <= 0x044f) {
      return 0xe0 + codePoint - 0x0430;
    }
    throw StateError(
      'Unsupported test character U+${codePoint.toRadixString(16)}',
    );
  }).toList(),
);

final _importTime = DateTime.utc(2026, 7, 15, 17);

BookProject _sourceProject() {
  final timestamp = DateTime.utc(2026, 7, 15, 9, 30, 45);
  final part = BookSection(
    id: 'part-1',
    title: 'Часть первая',
    type: BookSectionType.part,
    status: DraftStatus.complete,
    content: const [
      {'insert': 'Вступление\n'},
    ],
    createdAt: timestamp,
    updatedAt: timestamp,
  );
  final chapter = BookSection(
    id: 'chapter-1',
    title: 'Глава первая',
    type: BookSectionType.chapter,
    status: DraftStatus.complete,
    parentId: part.id,
    content: const [
      {
        'insert': 'Жирный текст',
        'attributes': {'bold': true},
      },
      {'insert': '\n'},
      {'insert': 'Обычный абзац\n'},
    ],
    createdAt: timestamp,
    updatedAt: timestamp,
  );
  return BookProject(
    id: 'source-book',
    metadata: const BookMetadata(
      title: 'Книга & море',
      subtitle: 'Подзаголовок',
      author: 'Иван Тестов',
      description: 'Описание',
      genre: 'Фэнтези',
    ),
    sections: [part, chapter],
    activeSectionId: chapter.id,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
