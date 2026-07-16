import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_epub_exporter.dart';
import 'package:dnevnik/features/books/application/book_export_content.dart';
import 'package:dnevnik/features/books/application/book_fb2_exporter.dart';
import 'package:dnevnik/features/books/application/book_html_exporter.dart';
import 'package:dnevnik/features/books/application/book_image_file.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validates supported image bytes instead of trusting the extension', () {
    final asset = BookImageFileCodec.createAsset(
      BookImageFile(name: 'picture.txt', bytes: _png),
      id: 'image-1',
    );

    expect(asset?.mediaType, 'image/png');
    expect(asset?.sourcePath, 'picture.txt');
    expect(
      BookImageFileCodec.createAsset(
        BookImageFile(name: 'fake.png', bytes: Uint8List.fromList([1, 2, 3])),
      ),
      isNull,
    );
  });

  test('parses both authored and imported image embeds', () {
    final blocks = BookExportContentParser.parse([
      {
        'insert': {'custom': '{"bookImage":"authored"}'},
      },
      {'insert': '\n'},
      {
        'insert': {'bookImage': 'imported'},
      },
      {'insert': '\n'},
    ]);

    expect(
      blocks
          .where((block) => block.type == BookExportBlockType.image)
          .map((block) => block.assetId),
      ['authored', 'imported'],
    );
  });

  test('embeds manuscript images in EPUB, FB2, and HTML exports', () {
    final project = _project();

    final epub = ZipDecoder().decodeBytes(
      BookEpubExporter.create(project).bytes,
    );
    final epubFiles = {for (final file in epub.files) file.name: file};
    expect(epubFiles, contains('EPUB/images/image-1.png'));
    expect(
      utf8.decode(epubFiles['EPUB/text/section-001.xhtml']!.content),
      contains('../images/image-1.png'),
    );

    final fb2 = utf8.decode(BookFb2Exporter.create(project).bytes);
    expect(fb2, contains('<image l:href="#image-1"/>'));
    expect(fb2, contains('<binary id="image-1" content-type="image/png">'));

    final html = utf8.decode(BookHtmlExporter.create(project).bytes);
    expect(html, contains('data:image/png;base64,'));
  });
}

BookProject _project() {
  final now = DateTime.utc(2026);
  final asset = BookAsset(
    id: 'image-1',
    mediaType: 'image/png',
    bytes: _png,
    sourcePath: 'pixel.png',
  );
  return BookProject(
    id: 'image-book',
    metadata: const BookMetadata(title: 'Книга с изображением'),
    sections: [
      BookSection(
        id: 'chapter',
        title: 'Глава',
        type: BookSectionType.chapter,
        status: DraftStatus.draft,
        content: const [
          {
            'insert': {'bookImage': 'image-1'},
          },
          {'insert': '\n'},
        ],
        createdAt: now,
        updatedAt: now,
      ),
    ],
    activeSectionId: 'chapter',
    createdAt: now,
    updatedAt: now,
    assets: [asset],
  );
}

final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);
