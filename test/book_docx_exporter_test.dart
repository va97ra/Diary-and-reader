import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_docx_exporter.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates an editable WordprocessingML package with book structure', () {
    final project = _project();

    final artifact = BookDocxExporter.create(project);
    final archive = ZipDecoder().decodeBytes(artifact.bytes);
    final files = {for (final file in archive.files) file.name: file};

    expect(artifact.extension, 'docx');
    expect(artifact.mimeType, BookDocxExporter.mimeType);
    expect(artifact.bytes.take(2), [0x50, 0x4b]);
    expect(
      files.keys,
      containsAll(<String>[
        '[Content_Types].xml',
        '_rels/.rels',
        'docProps/core.xml',
        'docProps/app.xml',
        'word/document.xml',
        'word/_rels/document.xml.rels',
        'word/styles.xml',
        'word/numbering.xml',
        'word/settings.xml',
        'word/fontTable.xml',
        'word/header1.xml',
        'word/footer1.xml',
        'word/media/image-1.png',
      ]),
    );

    final document = _text(files['word/document.xml']!);
    expect(document, contains('Книга &amp; море'));
    expect(document, contains('Автор &lt;Тест&gt;'));
    expect(document, contains('TOC \\o &quot;1-3&quot;'));
    expect(document, contains('w:name="section_2"'));
    expect(document, contains('w:pageBreakBefore'));
    expect(document, contains('<w:b/>'));
    expect(document, contains('<w:u w:val="single"/>'));
    expect(document, contains('[x] '));
    expect(document, contains('w:numId w:val="10"'));
    expect(document, contains('<w:drawing>'));
    expect(document, contains('r:embed="rId100"'));
    expect(RegExp('<w:br w:type="page"/>').allMatches(document), hasLength(3));
    expect(document, contains('w:orient="landscape"'));
    expect(document, contains('<w:pgSz w:w="16838" w:h="11906"'));
    expect(
      document,
      contains('w:top="850" w:right="1134" w:bottom="850" w:left="1417"'),
    );

    final relationships = _text(files['word/_rels/document.xml.rels']!);
    expect(relationships, contains('Target="https://example.com/book"'));
    expect(relationships, contains('TargetMode="External"'));
    expect(relationships, contains('Target="media/image-1.png"'));
    expect(relationships, contains('/relationships/image'));

    final styles = _text(files['word/styles.xml']!);
    expect(styles, contains('w:styleId="BodyText"'));
    expect(styles, contains('Times New Roman'));
    expect(styles, contains('w:firstLine="283"'));

    final numbering = _text(files['word/numbering.xml']!);
    expect(numbering, contains('<w:num w:numId="10">'));
    expect(numbering, contains('<w:num w:numId="11">'));
    expect(numbering, contains('<w:numFmt w:val="decimal"/>'));
    expect(numbering, contains('<w:numFmt w:val="bullet"/>'));

    final settings = _text(files['word/settings.xml']!);
    expect(settings, contains('<w:updateFields w:val="true"/>'));

    final core = _text(files['docProps/core.xml']!);
    expect(core, contains('<dc:title>Книга &amp; море</dc:title>'));
    expect(core, contains('2026-07-15T09:30:45Z'));
  });

  test('keeps TOC text while hiding chapter heading paragraphs', () {
    final project = _project().copyWith(
      layoutSettings: const BookLayoutSettings(showChapterTitlesInBody: false),
    );
    final archive = ZipDecoder().decodeBytes(
      BookDocxExporter.create(project).bytes,
    );
    final document = _text(
      archive.files.singleWhere((file) => file.name == 'word/document.xml'),
    );

    expect(document, contains('Глава &amp; первая'));
    expect(
      document,
      isNot(
        contains(
          '<w:pStyle w:val="Heading2"/><w:pageBreakBefore/></w:pPr><w:bookmarkStart w:id="2"',
        ),
      ),
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
        'insert': 'Жирный и подчёркнутый текст',
        'attributes': {'bold': true, 'underline': true},
      },
      {'insert': '\n'},
      {
        'insert': {'bookImage': 'image-1'},
      },
      {'insert': '\n'},
      {
        'insert': {'bookPageBreak': '1'},
      },
      {'insert': '\n'},
      {'insert': 'Первый пункт'},
      {
        'insert': '\n',
        'attributes': {'list': 'ordered'},
      },
      {'insert': 'Маркер'},
      {
        'insert': '\n',
        'attributes': {'list': 'bullet'},
      },
      {'insert': 'Готово'},
      {
        'insert': '\n',
        'attributes': {'list': 'checked'},
      },
      {
        'insert': 'ссылка',
        'attributes': {'link': 'https://example.com/book'},
      },
      {'insert': '\n'},
    ],
    createdAt: timestamp,
    updatedAt: timestamp,
  );
  return BookProject(
    id: 'book-docx-test',
    metadata: const BookMetadata(
      title: 'Книга & море',
      subtitle: 'Подзаголовок',
      author: 'Автор <Тест>',
      description: 'Описание',
      genre: 'Роман',
      publisher: 'Издатель',
      rights: 'Все права защищены',
    ),
    sections: [part, chapter],
    activeSectionId: chapter.id,
    createdAt: timestamp,
    updatedAt: timestamp,
    layoutSettings: const BookLayoutSettings(
      orientation: BookPageOrientation.landscape,
      marginTopMm: 15,
      marginRightMm: 20,
      marginBottomMm: 15,
      marginLeftMm: 25,
    ),
    paragraphSettings: const BookParagraphSettings(
      fontFamily: 'Times New Roman',
      fontSizePt: 12,
      lineHeight: 1.5,
      paragraphIndentMm: 5,
    ),
    assets: [
      BookAsset(
        id: 'image-1',
        mediaType: 'image/png',
        bytes: _png,
        sourcePath: 'pixel.png',
      ),
    ],
  );
}

final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

String _text(ArchiveFile file) => utf8.decode(file.content);
