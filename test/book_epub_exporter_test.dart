import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_epub_exporter.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates a portable EPUB 3 archive with metadata and reading order', () {
    final project = _project();

    final artifact = BookEpubExporter.create(project);
    final archive = ZipDecoder().decodeBytes(artifact.bytes);
    final files = {for (final file in archive.files) file.name: file};

    expect(artifact.extension, 'epub');
    expect(artifact.mimeType, 'application/epub+zip');
    expect(archive.files.first.name, 'mimetype');
    expect(archive.files.first.compression, CompressionType.none);
    expect(_text(archive.files.first), 'application/epub+zip');
    expect(
      files.keys,
      containsAll(<String>[
        'META-INF/container.xml',
        'EPUB/package.opf',
        'EPUB/nav.xhtml',
        'EPUB/styles/book.css',
        'EPUB/text/title.xhtml',
        'EPUB/text/section-001.xhtml',
        'EPUB/text/section-002.xhtml',
        'EPUB/text/section-003.xhtml',
      ]),
    );

    final container = _text(files['META-INF/container.xml']!);
    expect(container, contains('full-path="EPUB/package.opf"'));

    final package = _text(files['EPUB/package.opf']!);
    expect(package, contains('<dc:title>Книга &amp; море</dc:title>'));
    expect(package, contains('<dc:creator>Автор &lt;Тест&gt;</dc:creator>'));
    expect(package, contains('<dc:language>ru</dc:language>'));
    expect(package, contains('2026-07-15T09:30:45Z'));
    expect(RegExp(r'<itemref ').allMatches(package), hasLength(4));

    final navigation = _text(files['EPUB/nav.xhtml']!);
    expect(navigation, contains('epub:type="toc"'));
    expect(navigation, contains('Часть первая'));
    expect(navigation, contains('Глава &amp; первая'));
    expect(navigation, contains('Сцена первая'));
    expect(navigation, contains('<ol>'));

    final chapter = _text(files['EPUB/text/section-002.xhtml']!);
    expect(chapter, contains('<strong>Жирный &amp; текст</strong>'));
    expect(chapter, contains('<h2>Заголовок</h2>'));
    expect(chapter, contains('<ul>'));
    expect(chapter, contains('<li>Пункт</li>'));
    expect(chapter, contains('<a href="https://example.com">ссылка</a>'));
  });

  test('keeps a chapter in navigation when its body title is hidden', () {
    final project = _project().copyWith(
      layoutSettings: const BookLayoutSettings(showChapterTitlesInBody: false),
    );
    final archive = ZipDecoder().decodeBytes(
      BookEpubExporter.create(project).bytes,
    );
    final files = {for (final file in archive.files) file.name: file};

    expect(_text(files['EPUB/nav.xhtml']!), contains('Глава &amp; первая'));
    expect(
      _text(files['EPUB/text/section-002.xhtml']!),
      isNot(contains('<h1>Глава &amp; первая</h1>')),
    );
  });
}

BookProject _project() {
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
    title: 'Глава & первая',
    type: BookSectionType.chapter,
    status: DraftStatus.complete,
    parentId: part.id,
    content: const [
      {
        'insert': 'Жирный & текст',
        'attributes': {'bold': true},
      },
      {'insert': '\n'},
      {'insert': 'Заголовок'},
      {
        'insert': '\n',
        'attributes': {'header': 1},
      },
      {'insert': 'Пункт'},
      {
        'insert': '\n',
        'attributes': {'list': 'bullet'},
      },
      {
        'insert': 'ссылка',
        'attributes': {'link': 'https://example.com'},
      },
      {'insert': '\n'},
    ],
    createdAt: timestamp,
    updatedAt: timestamp,
  );
  final scene = BookSection(
    id: 'scene-1',
    title: 'Сцена первая',
    type: BookSectionType.scene,
    status: DraftStatus.draft,
    parentId: chapter.id,
    content: const [
      {'insert': 'Текст сцены\n'},
    ],
    createdAt: timestamp,
    updatedAt: timestamp,
  );
  return BookProject(
    id: 'book-test',
    metadata: const BookMetadata(
      title: 'Книга & море',
      subtitle: 'Подзаголовок',
      author: 'Автор <Тест>',
      description: 'Описание',
      series: 'Серия',
      genre: 'Роман',
      isbn: '978-0-00-000000-0',
      publisher: 'Издатель',
      rights: 'Все права защищены',
    ),
    sections: [part, chapter, scene],
    activeSectionId: chapter.id,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

String _text(ArchiveFile file) => utf8.decode(file.content);
