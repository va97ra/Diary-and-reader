import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('book project round-trips metadata and section hierarchy', () {
    final now = DateTime.utc(2026, 7, 14);
    final project = BookProject.create(
      title: 'Тестовая книга',
      chapterTitle: 'Глава 1',
      now: now,
    );
    final chapter = project.sections.single;
    final scene = BookSection.create(
      id: 'scene-1',
      title: 'Сцена 1',
      type: BookSectionType.scene,
      parentId: chapter.id,
      now: now,
    ).copyWith(targetWords: 1200);
    final withScene = project.copyWith(
      sections: [...project.sections, scene],
      activeSectionId: scene.id,
      paragraphSettings: BookParagraphSettings.forPreset(
        BookParagraphPreset.manuscript,
      ),
      readerSettings: const BookReaderSettings(
        theme: BookReaderTheme.dark,
        fontSize: 21,
      ),
      readerProgress: const BookReaderProgress(
        sectionId: 'scene-1',
        sectionProgress: 0.4,
      ),
      readerAnnotations: BookReaderAnnotations(
        bookmarks: [
          BookReaderBookmark.create(
            sectionId: scene.id,
            sectionProgress: 0.25,
            excerpt: 'Фрагмент сцены',
            now: now,
          ),
        ],
        notes: [
          BookReaderNote.create(
            sectionId: scene.id,
            sectionProgress: 0.25,
            excerpt: 'Фрагмент сцены',
            text: 'Проверить диалог',
            now: now,
          ),
        ],
        highlights: [
          BookReaderHighlight.create(
            sectionId: scene.id,
            sectionProgress: 0.3,
            startOffset: 4,
            endOffset: 16,
            excerpt: 'Выделение',
            color: BookReaderHighlightColor.green,
            now: now,
          ),
        ],
        quotes: [
          BookReaderQuote.create(
            sectionId: scene.id,
            sectionProgress: 0.35,
            startOffset: 20,
            endOffset: 30,
            text: 'Цитата',
            now: now,
          ),
        ],
      ),
      collectionName: 'В работе',
    );

    final restored = BookProject.fromJson(withScene.toJson());

    expect(restored.metadata.title, 'Тестовая книга');
    expect(restored.activeSection?.id, scene.id);
    expect(restored.childrenOf(chapter.id).single.title, 'Сцена 1');
    expect(restored.activeSection?.targetWords, 1200);
    expect(restored.paragraphSettings.preset, BookParagraphPreset.manuscript);
    expect(restored.paragraphSettings.lineHeight, 2);
    expect(restored.readerSettings.theme, BookReaderTheme.dark);
    expect(restored.readerSettings.fontSize, 21);
    expect(restored.readerProgress.sectionId, 'scene-1');
    expect(restored.readerProgress.sectionProgress, 0.4);
    expect(restored.collectionName, 'В работе');
    expect(
      restored.readerAnnotations.bookmarks.single.excerpt,
      'Фрагмент сцены',
    );
    expect(restored.readerAnnotations.notes.single.text, 'Проверить диалог');
    expect(
      restored.readerAnnotations.highlights.single.color,
      BookReaderHighlightColor.green,
    );
    expect(restored.readerAnnotations.quotes.single.text, 'Цитата');
  });

  test('invalid active section falls back to the first section', () {
    final project = BookProject.fromJson({
      'id': 'book-1',
      'metadata': {'title': 'Книга'},
      'activeSectionId': 'missing',
      'sections': [
        {
          'id': 'chapter-1',
          'title': 'Глава 1',
          'type': 'chapter',
          'status': 'draft',
          'content': [
            {'insert': '\n'},
          ],
        },
      ],
    });

    expect(project.activeSectionId, 'chapter-1');
  });

  test('old projects preserve the former paragraph appearance', () {
    final project = BookProject.fromJson({
      'id': 'book-legacy',
      'metadata': {'title': 'Старая книга'},
      'sections': [
        {
          'id': 'chapter-1',
          'title': 'Глава 1',
          'type': 'chapter',
          'status': 'draft',
          'content': [
            {'insert': '\n'},
          ],
        },
      ],
    });

    expect(project.paragraphSettings.preset, BookParagraphPreset.custom);
    expect(project.paragraphSettings.lineHeight, 1.5);
    expect(project.paragraphSettings.spacingAfterPt, 0);
  });

  test('migrates automatic line height only for old document versions', () {
    Map<String, dynamic> source({int? version}) {
      final json = <String, dynamic>{
        'id': 'book-versioned',
        'metadata': {'title': 'Книга'},
        'sections': [
          {
            'id': 'chapter-1',
            'title': 'Глава 1',
            'type': 'chapter',
            'status': 'draft',
            'content': [
              {
                'insert': 'Текст\n',
                'attributes': {'line-height': '1.5'},
              },
            ],
          },
        ],
      };
      if (version != null) json['documentFormatVersion'] = version;
      return json;
    }

    final legacy = BookProject.fromJson(source());
    final current = BookProject.fromJson(source(version: 2));

    expect(
      legacy.activeSection!.content.single.containsKey('attributes'),
      isFalse,
    );
    expect(current.activeSection!.content.single['attributes'], {
      'line-height': '1.5',
    });
    expect(current.toJson()['documentFormatVersion'], 3);
  });
}
