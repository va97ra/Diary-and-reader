import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_bookmark_flag.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/literia_test_navigation.dart';
import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('single page mode paginates a long chapter and keeps progress', (
    tester,
  ) async {
    final controller = await _controllerWithLongChapter(
      const BookReaderSettings(
        viewMode: BookReaderViewMode.singlePage,
        contentWidth: 620,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1280, 820));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-1')));

    expect(
      find.byKey(const ValueKey('reader-single-page-view')),
      findsOneWidget,
    );
    expect(find.text('Глава 1'), findsOneWidget);
    expect(find.textContaining('Страница 1 из'), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-previous-page')), findsNothing);
    expect(find.byKey(const ValueKey('reader-next-page')), findsNothing);

    await tester.fling(
      find.byKey(const ValueKey('reader-page-swipe-area')),
      const Offset(-360, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-page-2')), findsOneWidget);
    expect(
      controller.activeProject!.readerProgress.sectionProgress,
      greaterThan(0),
    );

    await toggleReaderPanels(tester);
    await tester.tap(find.byKey(const ValueKey('reader-settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Лента'));
    await tester.pumpAndSettle();
    expect(
      controller.activeProject!.readerSettings.viewMode,
      BookReaderViewMode.continuous,
    );
    // The sheet hides itself to show the book in its new view.
    expect(find.text('Настройки чтения'), findsNothing);
    expect(
      find.byKey(const ValueKey('reader-continuous-view')),
      findsOneWidget,
    );
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('a page slot holds every line its paragraph renders', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    // Fifteen glyphs of the test font fill exactly the 300 px left beside
    // the caret in a 303 px column, so any extra width wraps the second word.
    controller.updateSectionContent([
      {'insert': 'aaaaaaa aaaaaaa\n'},
    ]);
    controller.updateReaderSettings(
      const BookReaderSettings(
        viewMode: BookReaderViewMode.singlePage,
        fontSize: 20,
        contentWidth: 303,
        horizontalPadding: 20,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-1')));

    final texts = <RenderEditable>[];
    void collect(RenderObject node) {
      if (node is RenderEditable) texts.add(node);
      node.visitChildren(collect);
    }

    collect(tester.renderObject(find.byKey(const ValueKey('reader-page-1'))));
    expect(texts, isNotEmpty);
    for (final text in texts) {
      expect(
        text.getMaxIntrinsicHeight(text.size.width),
        lessThanOrEqualTo(text.size.height + 0.5),
      );
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('spread shows two consecutive pages on a wide screen', (
    tester,
  ) async {
    final controller = await _controllerWithLongChapter(
      const BookReaderSettings(
        viewMode: BookReaderViewMode.spread,
        contentWidth: 560,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1500, 900));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-2')));

    expect(find.byKey(const ValueKey('reader-spread-view')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-page-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-page-2')), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(1024, 700));
    await tester.pump();
    expect(find.byKey(const ValueKey('reader-page-loading')), findsNothing);
    expect(find.byKey(const ValueKey('reader-page-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-page-2')), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('spread automatically becomes one page on a phone', (
    tester,
  ) async {
    final controller = await _controllerWithLongChapter(
      const BookReaderSettings(viewMode: BookReaderViewMode.spread),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-1')));

    expect(
      find.byKey(const ValueKey('reader-single-page-view')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reader-spread-view')), findsNothing);
    expect(find.byKey(const ValueKey('reader-page-2')), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('each page of a long chapter keeps a bookmark of its own', (
    tester,
  ) async {
    // So long that a page is less than two percent of the chapter.
    final controller = await _controllerWithLongChapter(
      const BookReaderSettings(
        viewMode: BookReaderViewMode.singlePage,
        contentWidth: 620,
      ),
      paragraphs: 400,
    );
    await tester.binding.setSurfaceSize(const Size(1280, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-1')));
    final bookmark = find.byKey(const ValueKey('reader-bookmark-action'));
    List<BookReaderBookmark> bookmarks() =>
        controller.activeProject!.readerAnnotations.bookmarks;

    await tester.tap(bookmark);
    await tester.pumpAndSettle();
    expect(bookmarks(), hasLength(1));
    // Its ribbon hangs from the page with the bookmark's number.
    Iterable<int> flagsOn(String page) => tester
        .widgetList<BookReaderBookmarkFlag>(
          find.descendant(
            of: find.ancestor(
              of: find.byKey(ValueKey(page)),
              matching: find.byType(Stack),
            ),
            matching: find.byType(BookReaderBookmarkFlag),
          ),
        )
        .map((flag) => flag.number);
    expect(flagsOn('reader-page-1'), [1]);

    await tester.fling(
      find.byKey(const ValueKey('reader-page-swipe-area')),
      const Offset(-360, 0),
      1200,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reader-page-2')), findsOneWidget);
    if (bookmark.evaluate().isEmpty) await toggleReaderPanels(tester);
    // The next page has no bookmark yet, so the button adds one.
    expect(
      find.descendant(of: bookmark, matching: find.byIcon(Icons.bookmark)),
      findsNothing,
    );
    await tester.tap(bookmark);
    await tester.pumpAndSettle();

    expect(bookmarks(), hasLength(2));
    expect(
      find.descendant(of: bookmark, matching: find.byIcon(Icons.bookmark)),
      findsOneWidget,
    );
    expect(flagsOn('reader-page-2'), [2]);
  });

  testWidgets('the continuous text shows a bookmark as a numbered ribbon', (
    tester,
  ) async {
    final controller = await _controllerWithLongChapter(
      const BookReaderSettings(),
    );
    await tester.binding.setSurfaceSize(const Size(1280, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await _pumpUntil(
      tester,
      find.byKey(const ValueKey('reader-continuous-view')),
    );
    expect(find.byType(BookReaderBookmarkFlag), findsNothing);

    await tester.tap(find.byKey(const ValueKey('reader-bookmark-action')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<BookReaderBookmarkFlag>(
            find.descendant(
              of: find.byKey(const ValueKey('reader-continuous-view')),
              matching: find.byType(BookReaderBookmarkFlag),
            ),
          )
          .map((flag) => flag.number),
      [1],
    );
  });

  testWidgets('a page on a phone stands between the floating panels', (
    tester,
  ) async {
    final controller = await _controllerWithLongChapter(
      const BookReaderSettings(viewMode: BookReaderViewMode.singlePage),
    );

    // The reader measures the phone by MediaQuery, so the view itself is
    // phone sized, not only the test surface.
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-1')));
    final page = tester.getRect(find.byKey(const ValueKey('reader-page-1')));

    // The panels show when the book opens and cover no line of the page.
    final top = tester.getRect(
      find.byKey(const ValueKey('book-compact-top-panel')),
    );
    final bottom = tester.getRect(
      find.byKey(const ValueKey('book-compact-bottom-panel')),
    );
    expect(page.top, greaterThanOrEqualTo(top.bottom));
    expect(page.bottom, lessThanOrEqualTo(bottom.top));
  });

  testWidgets('the continuous text opens at its place below the top panel', (
    tester,
  ) async {
    final controller = await _controllerWithLongChapter(
      const BookReaderSettings(viewMode: BookReaderViewMode.continuous),
    );
    final section = controller.activeSection!;
    final paragraphs = [
      for (final operation in section.content) operation['insert'] as String,
    ];
    final total = paragraphs.join().length;
    final thirtieth = paragraphs.take(29).join().length;
    controller.updateReaderProgress(
      BookReaderProgress(
        sectionId: section.id,
        sectionProgress: (thirtieth + 2) / total,
      ),
    );
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await tester.pumpAndSettle();

    // The paragraph read last stands right under the top panel, not
    // behind it: in a short chapter that left the screen looking empty.
    final paragraph = tester.getRect(
      find.byKey(const ValueKey('reader-block-29')),
    );
    final top = tester.getRect(
      find.byKey(const ValueKey('book-compact-top-panel')),
    );
    final bottom = tester.getRect(
      find.byKey(const ValueKey('book-compact-bottom-panel')),
    );
    expect(paragraph.top, greaterThanOrEqualTo(top.bottom - 4));
    expect(paragraph.top, lessThan(bottom.top));
  });

  testWidgets('turning the phone keeps the place in the continuous text', (
    tester,
  ) async {
    final controller = await _controllerWithLongChapter(
      const BookReaderSettings(viewMode: BookReaderViewMode.continuous),
    );
    final section = controller.activeSection!;
    final paragraphs = [
      for (final operation in section.content) operation['insert'] as String,
    ];
    final total = paragraphs.join().length;
    final thirtieth = paragraphs.take(29).join().length;
    final place = (thirtieth + 2) / total;
    controller.updateReaderProgress(
      BookReaderProgress(sectionId: section.id, sectionProgress: place),
    );
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await tester.pumpAndSettle();

    // On its side every line wraps anew and the panels move to the sides:
    // the paragraph read stays at the top, where the next touch would save
    // whatever text stood there. Then back upright.
    final continuous = find.byKey(const ValueKey('reader-continuous-view'));
    Rect paragraph() =>
        tester.getRect(find.byKey(const ValueKey('reader-block-29')));
    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();
    expect(
      paragraph().top - tester.getRect(continuous).top,
      lessThan(const BookReaderSettings().verticalPadding + 8),
    );
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    final saved = controller.activeProject!.readerProgress.sectionProgress;
    expect(saved, closeTo(place, 0.003));
    final top = tester.getRect(
      find.byKey(const ValueKey('book-compact-top-panel')),
    );
    expect(paragraph().top, closeTo(top.bottom, 24));
  });

  testWidgets('paged reader stays usable in compact landscape constraints', (
    tester,
  ) async {
    final controller = await _controllerWithLongChapter(
      const BookReaderSettings(
        viewMode: BookReaderViewMode.singlePage,
        fontSize: 32,
        verticalPadding: 80,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-1')));
    // Cross the adaptive-control breakpoint to exercise stateful reparenting
    // between the compact top/bottom bars and the wide side panels.
    await tester.binding.setSurfaceSize(const Size(900, 420));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('next chapter appears without a pagination placeholder', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent([
      {'insert': 'Короткая первая глава.\n'},
    ]);
    final firstChapterId = controller.activeSection!.id;
    controller.addSection(BookSectionType.chapter);
    controller.updateSectionTitle('Большая следующая глава');
    controller.updateSectionContent([
      for (var index = 0; index < 180; index++)
        {
          'insert':
              'Абзац $index следующей главы для продолжительного фонового расчёта страниц и проверки быстрого перехода.\n',
        },
    ]);
    final nextChapterId = controller.activeSection!.id;
    controller.selectSection(firstChapterId);
    controller.updateReaderSettings(
      const BookReaderSettings(viewMode: BookReaderViewMode.singlePage),
    );

    await tester.binding.setSurfaceSize(const Size(1280, 820));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-1')));

    await tester.fling(
      find.byKey(const ValueKey('reader-page-swipe-area')),
      const Offset(-360, 0),
      1200,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(controller.activeProject!.readerProgress.sectionId, nextChapterId);
    expect(find.byKey(const ValueKey('reader-page-1')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reader-page-background-loading')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('reader-page-loading')), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('last reader page continues with the next chapter', (
    tester,
  ) async {
    final controller = await _controllerWithLongChapter(
      const BookReaderSettings(
        viewMode: BookReaderViewMode.singlePage,
        contentWidth: 620,
      ),
    );
    final firstChapterId = controller.activeProject!.sections.single.id;
    controller.addSection(BookSectionType.chapter);
    controller.updateSectionTitle('Следующая глава');
    controller.updateSectionContent([
      {'insert': 'Продолжение книги без ручного выбора главы.\n'},
    ]);
    controller.selectSection(firstChapterId);

    await tester.binding.setSurfaceSize(const Size(1280, 820));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-1')));

    for (var page = 0; page < 40; page++) {
      if (controller.activeProject!.readerProgress.sectionId !=
          firstChapterId) {
        break;
      }
      await tester.fling(
        find.byKey(const ValueKey('reader-page-swipe-area')),
        const Offset(-360, 0),
        1200,
      );
      await tester.pumpAndSettle();
    }

    expect(
      controller.activeProject!.readerProgress.sectionId,
      controller.activeProject!.sections.last.id,
    );
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('continuous reader advances after scrolling to chapter end', (
    tester,
  ) async {
    final controller = await _controllerWithLongChapter(
      const BookReaderSettings(viewMode: BookReaderViewMode.continuous),
    );
    final firstChapterId = controller.activeProject!.sections.single.id;
    controller.addSection(BookSectionType.chapter);
    controller.updateSectionTitle('Глава после прокрутки');
    controller.updateSectionContent([
      {'insert': 'Текст следующей главы.\n'},
    ]);
    controller.selectSection(firstChapterId);

    await tester.binding.setSurfaceSize(const Size(1280, 700));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await tester.pumpAndSettle();
    final firstDocument = find.byKey(
      ValueKey('reader-document-$firstChapterId'),
    );

    for (var attempt = 0; attempt < 12; attempt++) {
      if (controller.activeProject!.readerProgress.sectionId !=
          firstChapterId) {
        break;
      }
      await tester.drag(firstDocument, const Offset(0, -900));
      await tester.pumpAndSettle();
    }

    expect(
      controller.activeProject!.readerProgress.sectionId,
      controller.activeProject!.sections.last.id,
    );
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('continuous reader swipes between short chapters', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent([
      {'insert': 'Короткая первая глава.\n'},
    ]);
    final firstChapterId = controller.activeSection!.id;
    controller.addSection(BookSectionType.chapter);
    controller.updateSectionTitle('Короткая вторая глава');
    controller.updateSectionContent([
      {'insert': 'Короткая вторая глава.\n'},
    ]);
    final secondChapterId = controller.activeSection!.id;
    controller.selectSection(firstChapterId);
    controller.updateReaderSettings(
      const BookReaderSettings(viewMode: BookReaderViewMode.continuous),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await tester.pumpAndSettle();

    await toggleReaderPanels(tester);
    final continuousView = find.byKey(const ValueKey('reader-continuous-view'));
    final viewBounds = tester.getRect(continuousView);
    final forwardGesture = await tester.startGesture(
      Offset(viewBounds.center.dx, viewBounds.bottom - 24),
    );
    await forwardGesture.moveBy(const Offset(0, -240));
    await forwardGesture.up();
    await tester.pumpAndSettle();
    expect(controller.activeProject!.readerProgress.sectionId, secondChapterId);

    await tester.drag(
      find.byKey(ValueKey('reader-document-$secondChapterId')),
      const Offset(0, 240),
    );
    await tester.pumpAndSettle();
    expect(controller.activeProject!.readerProgress.sectionId, firstChapterId);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('desktop keyboard crosses chapter boundaries', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent([
      {'insert': 'Первая короткая глава.\n'},
    ]);
    final firstChapterId = controller.activeSection!.id;
    controller.addSection(BookSectionType.chapter);
    controller.updateSectionTitle('Вторая глава');
    controller.updateSectionContent([
      {'insert': 'Вторая короткая глава.\n'},
    ]);
    final secondChapterId = controller.activeSection!.id;
    controller.selectSection(firstChapterId);
    controller.updateReaderSettings(
      const BookReaderSettings(viewMode: BookReaderViewMode.singlePage),
    );

    await tester.binding.setSurfaceSize(const Size(1280, 820));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openReaderPreview(tester, controller);
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-1')));

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(controller.activeProject!.readerProgress.sectionId, secondChapterId);

    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle();
    expect(controller.activeProject!.readerProgress.sectionId, firstChapterId);
    expect(controller.activeProject!.readerProgress.sectionProgress, 1);

    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        device: 41,
        position: tester.getCenter(find.byKey(const ValueKey('reader-page-1'))),
        scrollDelta: const Offset(0, 120),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.activeProject!.readerProgress.sectionId, secondChapterId);

    await tester.binding.setSurfaceSize(null);
  });
}

Future<AuthorWorkspaceController> _controllerWithLongChapter(
  BookReaderSettings settings, {
  int paragraphs = 45,
}) async {
  final controller = AuthorWorkspaceController(
    MemoryAuthorWorkspaceRepository(),
  );
  await controller.load(preferredLanguage: 'ru');
  controller.updateSectionContent([
    for (var index = 1; index <= paragraphs; index++)
      {
        'insert':
            '$index. Это длинный проверочный абзац главы, который нужен для точной пагинации текста в режиме чтения на нескольких последовательных страницах.\n',
      },
  ]);
  controller.updateReaderSettings(settings);
  await controller.flush();
  return controller;
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 80,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}
