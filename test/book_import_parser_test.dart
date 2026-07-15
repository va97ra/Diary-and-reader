import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
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
      expect(imported.assets, hasLength(1));
      expect(imported.coverAsset, isNotNull);
      expect(
        imported.sections.first.content.any((operation) {
          final insert = operation['insert'];
          return insert is Map && insert['bookImage'] != null;
        }),
        isTrue,
      );
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

    test('imports an EPUB cover and relative inline images', () {
      final imported = BookImportParser.parse(
        BookImportFile(name: 'illustrated.epub', bytes: _illustratedEpub()),
        now: _importTime,
      );

      expect(imported.assets, hasLength(1));
      expect(imported.coverAsset?.mediaType, 'image/png');
      expect(imported.coverAsset?.bytes, _tinyPng);
      expect(
        imported.sections.single.content.any((operation) {
          final insert = operation['insert'];
          return insert is Map && insert['bookImage'] != null;
        }),
        isTrue,
      );
    });

    test('keeps a supported image-only FB2 section', () {
      final xml = '''<?xml version="1.0" encoding="UTF-8"?>
<FictionBook xmlns:l="http://www.w3.org/1999/xlink"><description><title-info><book-title>Альбом</book-title></title-info></description><body><section><title><p>Иллюстрация</p></title><image l:href="#picture"/></section></body><binary id="picture" content-type="image/png">$_tinyPngBase64</binary></FictionBook>''';

      final imported = BookImportParser.parse(
        BookImportFile(
          name: 'album.fb2',
          bytes: Uint8List.fromList(utf8.encode(xml)),
        ),
        now: _importTime,
      );

      expect(imported.sections, hasLength(1));
      expect(imported.assets, hasLength(1));
      expect(richDocumentHasContent(imported.sections.single.content), isTrue);
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
          bytes: File('test/fixtures/import_sample.fb2').readAsBytesSync(),
        ),
        now: _importTime,
      );

      final restored = BookProject.fromJson(imported.toJson());

      expect(restored.kind, BookProjectKind.importedBook);
      expect(restored.sourceFormat, 'FB2');
      expect(restored.sourceFileName, 'book.fb2');
      expect(restored.readerProgress.sectionId, restored.sections.first.id);
      expect(restored.assets, hasLength(1));
      expect(restored.coverAsset?.bytes, imported.coverAsset?.bytes);
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

Uint8List _illustratedEpub() {
  final archive = Archive()
    ..add(
      ArchiveFile.string(
        'META-INF/container.xml',
        '''<?xml version="1.0"?><container xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="EPUB/package.opf"/></rootfiles></container>''',
      ),
    )
    ..add(
      ArchiveFile.string(
        'EPUB/package.opf',
        '''<?xml version="1.0"?><package xmlns="http://www.idpf.org/2007/opf" version="3.0"><metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>Иллюстрированная книга</dc:title><dc:language>ru</dc:language></metadata><manifest><item id="chapter" href="text/chapter.xhtml" media-type="application/xhtml+xml"/><item id="cover" href="images/cover.png" media-type="image/png" properties="cover-image"/></manifest><spine><itemref idref="chapter"/></spine></package>''',
      ),
    )
    ..add(
      ArchiveFile.string(
        'EPUB/text/chapter.xhtml',
        '''<?xml version="1.0"?><html xmlns="http://www.w3.org/1999/xhtml"><head><title>Глава</title></head><body><h1>Глава</h1><p>Перед иллюстрацией</p><img src="../images/cover.png" alt="Обложка"/></body></html>''',
      ),
    )
    ..add(ArchiveFile('EPUB/images/cover.png', _tinyPng.length, _tinyPng));
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}

const _tinyPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAADwAAABaCAYAAADkUTU1AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAFdSURBVHhe7dfBrcJAEINhCqECmuBCxzRFF6A9IK2sRLM7eLLI8eG7PMjE/413ud4e7zO54B/UOVidg9U5WJ2D1TlYnYPVTQe/nve/gvsiDo7gC1fDfREHR/CFq+G+iIPVOVidg9U5WJ2D1R0ajL+SfvnFlFUejGEj8AZTaTCGzMBbLCXBOH4kAr878kwGPRgHz47GZ2efj5QH4+cjGDf2UIOZQ5m3erTgioEVN0uC8bNfsO86OIM9CjHvOziDOWgL876DM5iDtjDvOziDOWgL8z4luGGO6rHvOjirH8YaV3GTFtwwBzJv9ajBDWMo48ae8uDZwfjs7PMRenCDg0eG43dHnskoCf7C8TPwFktpcIMhI/AGU3lwD8OOiuwdGvwPHKzOweocrM7B6hyszsHqHBzBf+tWw30RB0fwhavhvoiDI/jC1XBfxMHqHKzOweocrM7B6hyszsHqThf8ARS6xia/bURvAAAAAElFTkSuQmCC';
final _tinyPng = Uint8List.fromList(base64Decode(_tinyPngBase64));

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
