import 'dart:convert';

import 'package:dnevnik/features/books/application/book_pdf_exporter.dart';
import 'package:dnevnik/features/books/data/book_pdf_asset_font_loader.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'creates a Cyrillic print PDF with contents and embedded fonts',
    () async {
      final project = _project();
      final fonts = await const BookPdfAssetFontLoader().load();

      final artifact = await BookPdfExporter.create(
        project: project,
        fontAssets: fonts,
      );

      expect(artifact.extension, 'pdf');
      expect(artifact.mimeType, 'application/pdf');
      expect(ascii.decode(artifact.bytes.take(5).toList()), '%PDF-');
      expect(artifact.bytes.length, greaterThan(20000));
    },
  );

  test('uses the project paper orientation and physical margins', () {
    final project = _project().copyWith(
      layoutSettings: const BookLayoutSettings(
        orientation: BookPageOrientation.landscape,
        marginTopMm: 12,
        marginRightMm: 18,
        marginBottomMm: 22,
        marginLeftMm: 25,
      ),
    );

    final format = BookPdfExporter.formatFor(project);

    expect(format.width / PdfPageFormat.mm, closeTo(297, 0.001));
    expect(format.height / PdfPageFormat.mm, closeTo(210, 0.001));
    expect(format.marginTop / PdfPageFormat.mm, closeTo(12, 0.001));
    expect(format.marginRight / PdfPageFormat.mm, closeTo(18, 0.001));
    expect(format.marginBottom / PdfPageFormat.mm, closeTo(22, 0.001));
    expect(format.marginLeft / PdfPageFormat.mm, closeTo(25, 0.001));
  });
}

BookProject _project() {
  final timestamp = DateTime.utc(2026, 7, 15, 12);
  final part = BookSection(
    id: 'part-1',
    title: 'Часть первая',
    type: BookSectionType.part,
    status: DraftStatus.complete,
    content: const [
      {'insert': 'Вступление в книгу.\n'},
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
    content: [
      const {'insert': 'Заголовок раздела'},
      const {
        'insert': '\n',
        'attributes': {'header': 1},
      },
      for (var index = 0; index < 35; index++) ...[
        {
          'insert':
              'Абзац ${index + 1}. Это проверочный русский текст для переноса между печатными страницами. ',
          'attributes': {'bold': index == 0},
        },
        const {'insert': 'Продолжение абзаца с корректной кириллицей.\n'},
      ],
      const {'insert': 'Первый пункт'},
      const {
        'insert': '\n',
        'attributes': {'list': 'ordered'},
      },
      const {'insert': 'Второй пункт'},
      const {
        'insert': '\n',
        'attributes': {'list': 'ordered'},
      },
    ],
    createdAt: timestamp,
    updatedAt: timestamp,
  );
  return BookProject(
    id: 'pdf-test',
    metadata: const BookMetadata(
      title: 'Проверочная книга',
      subtitle: 'Подзаголовок',
      author: 'Иван Автор',
      description: 'Описание печатной книги',
      publisher: 'Издательство',
      rights: 'Все права защищены',
    ),
    sections: [part, chapter],
    activeSectionId: chapter.id,
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
