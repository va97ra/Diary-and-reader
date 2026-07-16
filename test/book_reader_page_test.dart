import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('reader opens with contents and keeps independent settings', (
    tester,
  ) async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionTitle('Первая глава');
    controller.updateSectionContent([
      {'insert': 'Первый текст книги.\n'},
    ]);
    controller.addSection(BookSectionType.chapter);
    controller.updateSectionTitle('Вторая глава');
    controller.updateSectionContent([
      {'insert': 'Продолжение книги.\n'},
    ]);
    controller.selectSection(controller.activeProject!.sections.first.id);

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-book-reader')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-surface')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-contents')), findsOneWidget);
    var readerEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(
      readerEditor.controller.document.toPlainText(),
      contains('Первый текст книги.'),
    );
    expect(find.text('Раздел 1 из 2 · 0%'), findsOneWidget);

    readerEditor.controller.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 6),
      ChangeSource.local,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-selection-bar')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reader-highlight-yellow')));
    await tester.pumpAndSettle();
    expect(
      controller.activeProject!.readerAnnotations.highlights,
      hasLength(1),
    );
    expect(
      controller.activeProject!.readerAnnotations.highlights.single.excerpt,
      'Первый',
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    readerEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    readerEditor.controller.updateSelection(
      const TextSelection(baseOffset: 7, extentOffset: 12),
      ChangeSource.local,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-save-quote')));
    await tester.pumpAndSettle();
    expect(controller.activeProject!.readerAnnotations.quotes, hasLength(1));

    await tester.tap(
      find.byKey(const ValueKey('reader-export-annotations-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-export-markdown')),
      findsOneWidget,
    );
    Navigator.of(
      tester.element(find.byKey(const ValueKey('reader-export-markdown'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('reader-bookmark-button')));
    await tester.pumpAndSettle();
    expect(controller.activeProject!.readerAnnotations.bookmarks, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('reader-next-section')));
    await tester.pumpAndSettle();
    readerEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(
      readerEditor.controller.document.toPlainText(),
      contains('Продолжение книги.'),
    );
    expect(
      controller.activeProject!.readerProgress.sectionId,
      controller.activeProject!.sections.last.id,
    );

    await tester.tap(find.byKey(const ValueKey('reader-search-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reader-search-field')),
      'Первый текст',
    );
    await tester.pumpAndSettle();
    final results = find.byKey(const ValueKey('reader-search-results'));
    expect(results, findsOneWidget);
    final firstChapterResult = find.descendant(
      of: results,
      matching: find.text('Первая глава'),
    );
    expect(firstChapterResult, findsOneWidget);
    await tester.tap(firstChapterResult);
    await tester.pumpAndSettle();
    expect(find.text('Раздел 1 из 2 · 0%'), findsOneWidget);

    DefaultTabController.of(tester.element(find.byType(TabBar))).animateTo(3);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-add-note')));
    await tester.pumpAndSettle();
    final noteDialogContext = tester.element(
      find.byKey(const ValueKey('reader-note-field')),
    );
    expect(
      Theme.of(noteDialogContext).dialogTheme.backgroundColor,
      BookReaderPalette.forTheme(BookReaderTheme.sepia).surface,
    );
    await tester.enterText(
      find.byKey(const ValueKey('reader-note-field')),
      'Проверить начало главы',
    );
    await tester.tap(find.byKey(const ValueKey('reader-save-note')));
    await tester.pumpAndSettle();
    expect(
      controller.activeProject!.readerAnnotations.notes.single.text,
      'Проверить начало главы',
    );

    await tester.tap(find.byKey(const ValueKey('reader-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тёмная'));
    await tester.pumpAndSettle();
    expect(
      controller.activeProject!.readerSettings.theme,
      BookReaderTheme.dark,
    );

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('reader uses compact contents action on a phone', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-book-reader')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('reader-contents-button')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reader-contents')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-focus-mode-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-exit-focus-mode')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reader-progress')), findsNothing);
    expect(find.byKey(const ValueKey('reader-next-section')), findsNothing);
    expect(find.byKey(const ValueKey('reader-contents-button')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-exit-focus-mode')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-focus-mode-button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('reader-contents-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-contents')), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
}
