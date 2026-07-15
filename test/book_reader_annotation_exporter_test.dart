import 'dart:convert';

import 'package:dnevnik/features/books/application/book_reader_annotation_exporter.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports portable Markdown and structured JSON annotations', () {
    final now = DateTime.utc(2026, 7, 15, 10);
    final base = BookProject.create(
      title: 'Моя книга',
      chapterTitle: 'Глава 1',
      now: now,
    );
    final section = base.sections.single;
    final project = base.copyWith(
      metadata: base.metadata.copyWith(author: 'Автор'),
      readerAnnotations: BookReaderAnnotations(
        highlights: [
          BookReaderHighlight.create(
            sectionId: section.id,
            sectionProgress: 0.25,
            startOffset: 2,
            endOffset: 12,
            excerpt: 'Важный текст',
            color: BookReaderHighlightColor.yellow,
            now: now,
          ),
        ],
        quotes: [
          BookReaderQuote.create(
            sectionId: section.id,
            sectionProgress: 0.5,
            startOffset: 14,
            endOffset: 25,
            text: 'Точная цитата',
            now: now,
          ),
        ],
        notes: [
          BookReaderNote.create(
            sectionId: section.id,
            sectionProgress: 0.5,
            excerpt: 'Точная цитата',
            text: 'Проверить позже',
            now: now,
          ),
        ],
      ),
    );

    final markdown = BookReaderAnnotationExporter.create(
      project: project,
      format: BookReaderAnnotationExportFormat.markdown,
      languageCode: 'ru',
    );
    final json = BookReaderAnnotationExporter.create(
      project: project,
      format: BookReaderAnnotationExportFormat.json,
      languageCode: 'ru',
    );

    expect(markdown.extension, 'md');
    expect(markdown.content, contains('# Читательские аннотации — Моя книга'));
    expect(markdown.content, contains('## Глава 1'));
    expect(markdown.content, contains('🟨 “Важный текст” (25%)'));
    expect(markdown.content, contains('> Точная цитата'));
    expect(markdown.content, contains('**Проверить позже**'));

    final decoded = jsonDecode(json.content) as Map<String, dynamic>;
    expect(decoded['format'], 'dnevnik-reader-annotations');
    expect(decoded['version'], 1);
    final annotations = decoded['annotations'] as Map<String, dynamic>;
    expect(annotations['highlights'], hasLength(1));
    expect(annotations['quotes'], hasLength(1));
  });
}
