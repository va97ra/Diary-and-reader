import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_fb2_exporter.dart';
import 'package:dnevnik/features/books/application/book_html_exporter.dart';
import 'package:dnevnik/features/books/application/book_markdown_exporter.dart';
import 'package:dnevnik/features/books/application/book_txt_exporter.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  group('additional book exporters', () {
    test('creates well-formed FB2 with metadata and nested content sections', () {
      final artifact = BookFb2Exporter.create(_project());
      final content = utf8.decode(artifact.bytes);
      final document = XmlDocument.parse(content);

      expect(artifact.extension, 'fb2');
      expect(artifact.mimeType, 'application/x-fictionbook+xml');
      expect(document.rootElement.name.local, 'FictionBook');
      expect(document.rootElement.name.namespaceUri, BookFb2Exporter.namespace);
      expect(
        document.findAllElements('book-title').single.innerText,
        'Книга & море',
      );
      expect(content, contains('<genre>sf_fantasy</genre>'));
      expect(content, contains('<section id="section-1-text">'));
      expect(content, contains('<section id="section-2">'));
      expect(content, contains('<strong>Жирный &amp; текст</strong>'));
      expect(
        content,
        contains(
          '<a l:type="simple" l:href="https://example.com?a=1&amp;b=2">ссылка</a>',
        ),
      );
    });

    test('creates a readable FB2.ZIP archive containing one FB2 document', () {
      final artifact = BookFb2Exporter.createZip(_project());
      final archive = ZipDecoder().decodeBytes(artifact.bytes);

      expect(artifact.extension, 'fb2.zip');
      expect(artifact.mimeType, 'application/zip');
      expect(archive.files, hasLength(1));
      expect(archive.files.single.name, 'book.fb2');
      expect(
        () => XmlDocument.parse(utf8.decode(archive.files.single.content)),
        returnsNormally,
      );
    });

    test('creates standalone responsive HTML with escaped project data', () {
      final artifact = BookHtmlExporter.create(_project());
      final content = utf8.decode(artifact.bytes);

      expect(artifact.extension, 'html');
      expect(artifact.mimeType, 'text/html; charset=utf-8');
      expect(content, startsWith('<!doctype html>'));
      expect(content.substring(0, 1024), contains('<meta charset="utf-8">'));
      expect(content, contains('<title>Книга &amp; море</title>'));
      expect(content, contains('href="#section-2"'));
      expect(content, contains('<section id="section-2"'));
      expect(content, contains('<strong>Жирный &amp; текст</strong>'));
      expect(content, contains('@media (max-width: 600px)'));
    });

    test('creates structured Markdown and formatting-free UTF-8 text', () {
      final project = _project();
      final markdownArtifact = BookMarkdownExporter.create(project);
      final textArtifact = BookTxtExporter.create(project);
      final markdown = utf8.decode(markdownArtifact.bytes);
      final text = utf8.decode(textArtifact.bytes);

      expect(markdownArtifact.extension, 'md');
      expect(markdown, startsWith('# Книга & море'));
      expect(markdown, contains('## Часть первая'));
      expect(markdown, contains('### Глава & первая'));
      expect(markdown, contains('**Жирный & текст**'));
      expect(markdown, contains('[ссылка](https://example.com?a=1&b=2)'));
      expect(textArtifact.extension, 'txt');
      expect(text, startsWith('Книга & море\n============'));
      expect(text, contains('Жирный & текст'));
      expect(text, contains('• Пункт'));
      expect(text, isNot(contains('**Жирный')));
    });
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
      {'insert': 'Пункт'},
      {
        'insert': '\n',
        'attributes': {'list': 'bullet'},
      },
      {
        'insert': 'ссылка',
        'attributes': {'link': 'https://example.com?a=1&b=2'},
      },
      {'insert': '\n'},
    ],
    createdAt: timestamp,
    updatedAt: timestamp,
  );
  return BookProject(
    id: 'book-test',
    metadata: const BookMetadata(
      title: 'Книга & море',
      subtitle: 'Подзаголовок',
      author: 'Иван Тестов',
      description: 'Описание & аннотация',
      series: 'Серия',
      genre: 'Фэнтези',
      isbn: '978-0-00-000000-0',
      publisher: 'Издатель',
      rights: 'Все права защищены',
    ),
    sections: [part, chapter],
    activeSectionId: chapter.id,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
