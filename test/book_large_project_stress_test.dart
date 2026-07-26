@Timeout(Duration(seconds: 60))
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_import_parser.dart';
import 'package:dnevnik/features/books/application/book_manuscript_search.dart';
import 'package:dnevnik/features/books/application/book_page_paginator.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('searches and serializes a million-character manuscript', () {
    final stopwatch = Stopwatch()..start();
    final project = _largeProject(
      sectionCount: 240,
      charactersPerSection: 4200,
    );
    final matches = BookManuscriptSearch.find(project, 'контрольная фраза');
    final restored = BookProject.fromJson(project.toJson());
    stopwatch.stop();

    expect(matches, hasLength(240));
    expect(restored.sections, hasLength(240));
    expect(restored.sections.last.content, project.sections.last.content);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 15)));
  });

  test('splits and merges a very long chapter without data loss', () {
    final original = <Map<String, dynamic>>[
      {'insert': '${'Большая рукопись с длинными абзацами. ' * 30000}\n'},
    ];
    final pages = <RichDocument>[];
    var overflow = original;
    final stopwatch = Stopwatch()..start();
    while (_length(overflow) > 12000) {
      final split = BookPagePaginator.split(overflow, 12000);
      pages.add(split.visible);
      overflow = split.overflow;
    }
    pages.add(overflow);
    final merged = BookPagePaginator.merge(pages);
    stopwatch.stop();

    expect(pages.length, greaterThan(80));
    expect(_plain(merged), _plain(original));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 15)));
  });

  test('imports a large FB2 and keeps every generated chapter', () {
    final body = StringBuffer();
    for (var index = 0; index < 160; index += 1) {
      body.write(
        '<section><title><p>Глава $index</p></title>'
        '<p>${'Текст большой импортированной книги. ' * 120}</p></section>',
      );
    }
    final source = '''<?xml version="1.0" encoding="UTF-8"?>
<FictionBook><description><title-info><book-title>Большая книга</book-title>
</title-info></description><body>$body</body></FictionBook>''';
    final stopwatch = Stopwatch()..start();
    final project = BookImportParser.parse(
      BookImportFile(name: 'large.fb2', bytes: utf8.encode(source)),
    );
    stopwatch.stop();

    expect(project.sections, hasLength(160));
    expect(project.sections.last.title, 'Глава 159');
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 15)));
  });

  test('round-trips several megabytes of embedded image data', () {
    final project = _largeProject(sectionCount: 4, charactersPerSection: 1000);
    final payload = Uint8List.fromList(
      List<int>.generate(64 * 1024, (index) => index % 251),
    );
    final withImages = project.copyWith(
      assets: [
        for (var index = 0; index < 64; index += 1)
          BookAsset(
            id: 'image-$index',
            mediaType: 'image/png',
            bytes: payload,
            sourcePath: 'image-$index.png',
          ),
      ],
    );
    final stopwatch = Stopwatch()..start();
    final encoded = jsonEncode(withImages.toJson());
    final decoded = BookProject.fromJson(
      Map<String, dynamic>.from(jsonDecode(encoded) as Map),
    );
    stopwatch.stop();

    expect(decoded.assets, hasLength(64));
    expect(decoded.assets.last.bytes.length, payload.length);
    expect(encoded.length, greaterThan(5 * 1024 * 1024));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 15)));
  });
}

BookProject _largeProject({
  required int sectionCount,
  required int charactersPerSection,
}) {
  final now = DateTime.utc(2026, 7, 22);
  final paragraph = 'Обычный текст для проверки производительности. ';
  final repeated = paragraph * (charactersPerSection ~/ paragraph.length);
  final sections = [
    for (var index = 0; index < sectionCount; index += 1)
      BookSection(
        id: 'chapter-$index',
        title: 'Глава $index',
        type: BookSectionType.chapter,
        status: DraftStatus.draft,
        content: [
          {'insert': '$repeated контрольная фраза $index\n'},
        ],
        createdAt: now,
        updatedAt: now,
      ),
  ];
  return BookProject(
    id: 'large-project',
    metadata: const BookMetadata(title: 'Большая рукопись'),
    sections: sections,
    activeSectionId: sections.first.id,
    createdAt: now,
    updatedAt: now,
  );
}

int _length(RichDocument document) => document.fold(0, (sum, operation) {
  final insert = operation['insert'];
  return sum + (insert is String ? insert.length : 1);
});

String _plain(RichDocument document) => document
    .map((operation) => operation['insert'])
    .whereType<String>()
    .join()
    .replaceAll('\n\n', '\n');
