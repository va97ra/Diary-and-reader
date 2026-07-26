import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_contents.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_progress_rail.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_adaptive_control_shell.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/literia_test_navigation.dart';
import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('contents distinguishes repeated legacy chapter titles', (
    tester,
  ) async {
    final sections = [
      BookSection.create(
        id: 'one',
        title: 'Одинаковое название книги',
        type: BookSectionType.chapter,
      ),
      BookSection.create(
        id: 'two',
        title: 'Одинаковое название книги',
        type: BookSectionType.chapter,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: BookReaderContents(
            sections: sections,
            activeSectionId: 'one',
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Раздел 1'), findsOneWidget);
    expect(find.text('Раздел 2'), findsOneWidget);
  });

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
    await openReaderPreview(tester, controller);

    expect(find.byKey(const ValueKey('reader-surface')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-context-bar')), findsNothing);
    expect(find.byKey(const ValueKey('reader-left-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-right-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-contents')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('reader-contents-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-contents')), findsOneWidget);
    final openContents = find.byKey(const ValueKey('reader-contents'));
    if (openContents.evaluate().isNotEmpty) {
      Navigator.of(tester.element(openContents)).pop();
      await tester.pumpAndSettle();
    }
    var readerEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(
      readerEditor.controller.document.toPlainText(),
      contains('Первый текст книги.'),
    );

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

    await tester.tap(find.byKey(const ValueKey('reader-contents-action')));
    await tester.pumpAndSettle();
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
    final remainingContents = find.byKey(const ValueKey('reader-contents'));
    if (remainingContents.evaluate().isNotEmpty) {
      Navigator.of(tester.element(remainingContents)).pop();
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const ValueKey('reader-bookmark-action')));
    await tester.pumpAndSettle();
    expect(controller.activeProject!.readerAnnotations.bookmarks, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('reader-contents-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Вторая глава').last);
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

    await tester.tap(find.byKey(const ValueKey('reader-search-action')));
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
    await tester.tap(find.byKey(const ValueKey('reader-contents-action')));
    await tester.pumpAndSettle();
    DefaultTabController.of(tester.element(find.byType(TabBar))).animateTo(3);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-add-note')));
    await tester.pumpAndSettle();
    final noteDialogContext = tester.element(
      find.byKey(const ValueKey('reader-note-field')),
    );
    expect(find.byType(BookLeatherModalSurface), findsWidgets);
    expect(
      Theme.of(noteDialogContext).colorScheme.onSurface,
      BookLeatherColors.foreground,
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

    Navigator.of(
      tester.element(find.byKey(const ValueKey('reader-surface'))),
    ).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-settings-action')));
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
    await openReaderPreview(tester, controller);

    expect(
      find.byKey(const ValueKey('reader-contents-action')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.text('Поиск'), findsOneWidget);
    expect(find.text('Озвучка'), findsOneWidget);
    final searchButtonSize = tester.getSize(
      find.byKey(const ValueKey('reader-search-action')),
    );
    expect(searchButtonSize.width, greaterThanOrEqualTo(48));
    expect(searchButtonSize.height, greaterThanOrEqualTo(48));
    expect(find.byKey(const ValueKey('reader-previous-section')), findsNothing);
    expect(find.byKey(const ValueKey('reader-next-section')), findsNothing);
    expect(find.byKey(const ValueKey('reader-contents')), findsNothing);
    expect(find.byKey(const ValueKey('reader-progress')), findsNothing);
    expect(find.byKey(const ValueKey('reader-progress-rail')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('reader-progress-rail'))).width,
      3,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('reader-progress-rail'))).dx,
      0,
    );
    expect(find.text('Глава 1'), findsOneWidget);
    expect(
      tester
          .widget<BookReaderProgressRail>(find.byType(BookReaderProgressRail))
          .value,
      0,
    );
    final progressSemantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Прогресс чтения',
      ),
    );
    expect(progressSemantics.properties.value, '0%');
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('reader-progress-rail')),
        matching: find.byWidgetPredicate(
          (widget) => widget is IgnorePointer && widget.ignoring,
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('reader-hide-panels-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-exit-focus-mode')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reader-context-bar')), findsNothing);
    expect(find.byKey(const ValueKey('reader-next-section')), findsNothing);
    expect(find.byKey(const ValueKey('reader-contents-action')), findsNothing);
    expect(find.byKey(const ValueKey('reader-progress-rail')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reader-exit-focus-mode')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-hide-panels-button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('reader-contents-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-contents')), findsOneWidget);
    final contentsTabs = find.byType(TabBar);
    expect(
      find.descendant(of: contentsTabs, matching: find.text('Главы')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: contentsTabs, matching: find.text('Закладки')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: contentsTabs, matching: find.text('Выделения')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: contentsTabs, matching: find.text('Заметки')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reader-navigation-close')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('reader-navigation-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-contents')), findsNothing);

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('reader-surface'))),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-exit-focus-mode')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('reader-exit-focus-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-settings-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-settings-close')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-settings-close')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('reader-settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-settings-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-settings-close')), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });
}
