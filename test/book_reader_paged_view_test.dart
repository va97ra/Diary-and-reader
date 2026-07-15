import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await tester.tap(find.byKey(const ValueKey('open-book-reader')));
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-1')));

    expect(
      find.byKey(const ValueKey('reader-single-page-view')),
      findsOneWidget,
    );
    final nextButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('reader-next-page')),
    );
    expect(nextButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('reader-next-page')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-page-2')), findsOneWidget);
    expect(
      controller.activeProject!.readerProgress.sectionProgress,
      greaterThan(0),
    );

    await tester.tap(find.byKey(const ValueKey('reader-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Лента'));
    await tester.pumpAndSettle();
    expect(
      controller.activeProject!.readerSettings.viewMode,
      BookReaderViewMode.continuous,
    );
    Navigator.of(tester.element(find.text('Настройки чтения'))).pop();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reader-continuous-view')),
      findsOneWidget,
    );
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
    await tester.tap(find.byKey(const ValueKey('open-book-reader')));
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-2')));

    expect(find.byKey(const ValueKey('reader-spread-view')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-page-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-page-2')), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(1024, 700));
    await tester.pump();
    expect(find.byKey(const ValueKey('reader-page-loading')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-page-1')), findsNothing);
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-2')));

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
    await tester.tap(find.byKey(const ValueKey('open-book-reader')));
    await _pumpUntil(tester, find.byKey(const ValueKey('reader-page-1')));

    expect(
      find.byKey(const ValueKey('reader-single-page-view')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reader-spread-view')), findsNothing);
    expect(find.byKey(const ValueKey('reader-page-2')), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });
}

Future<AuthorWorkspaceController> _controllerWithLongChapter(
  BookReaderSettings settings,
) async {
  final controller = AuthorWorkspaceController(
    MemoryAuthorWorkspaceRepository(),
  );
  await controller.load(preferredLanguage: 'ru');
  controller.updateSectionContent([
    for (var index = 1; index <= 45; index++)
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
