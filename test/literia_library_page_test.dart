import 'dart:async';

import 'package:dnevnik/app/literia_library_page.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_library_query.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_adaptive_control_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('reading library switches layouts, searches, and favorites', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(seedManuscript: false),
    );
    await controller.load(preferredLanguage: 'ru');
    final seed =
        BookProject.create(
          title: 'Тестовая книга',
          chapterTitle: 'Глава',
        ).copyWith(
          kind: BookProjectKind.importedBook,
          metadata: const BookMetadata(
            title: 'Тестовая книга',
            author: 'Автор',
          ),
        );
    controller.addImportedBook(seed);

    await tester.binding.setSurfaceSize(const Size(900, 800));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LiteriaLibraryPage(
          mode: LiteriaLibraryMode.reading,
          controller: controller,
          onPrimaryAction: () async {},
          onOpen: (_) async {},
          onDelete: (_) async {},
          onAbout: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('library-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('library-control-panel')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(ValueKey('literia-project-${seed.id}')),
        matching: find.byType(BookLeatherPanel),
      ),
      findsOneWidget,
    );
    expect(find.byKey(ValueKey('literia-project-${seed.id}')), findsOneWidget);
    // An unread book shows an empty track, not a bar filled with the accent.
    final progressTheme = ProgressIndicatorTheme.of(
      tester.element(find.byType(LinearProgressIndicator)),
    );
    expect(progressTheme.linearTrackColor, isNotNull);
    expect(progressTheme.linearTrackColor, isNot(progressTheme.color));
    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pump();
    expect(controller.projects.single.libraryState.isFavorite, isTrue);

    await tester.tap(find.byKey(const ValueKey('library-layout-toggle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(ValueKey('literia-project-list-${seed.id}')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('library-search')),
      'нет такой книги',
    );
    await tester.pumpAndSettle();
    expect(find.text('По заданным условиям книг не найдено'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
    controller.dispose();
  });

  testWidgets('mobile library keeps leather controls on a compact grid', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(seedManuscript: false),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LiteriaLibraryPage(
          mode: LiteriaLibraryMode.reading,
          controller: controller,
          onPrimaryAction: () async {},
          onScanDeviceBooks: () async {},
          onOpen: (_) async {},
          onDelete: (_) async {},
          onAbout: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Search and every display control share one slim row.
    final controls = find.byKey(const ValueKey('library-control-panel'));
    expect(tester.getSize(controls).height, lessThan(90));
    expect(
      tester.getCenter(find.byKey(const ValueKey('library-search'))).dy,
      tester.getCenter(find.byKey(const ValueKey('library-sort-menu'))).dy,
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('library-layout-toggle'))).dy,
      tester.getCenter(find.byKey(const ValueKey('library-sort-menu'))).dy,
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('library-filter-menu'))).dy,
      tester.getCenter(find.byKey(const ValueKey('library-sort-menu'))).dy,
    );
    final layoutSize = tester.getSize(
      find.byKey(const ValueKey('library-layout-toggle')),
    );
    final sortSize = tester.getSize(
      find.byKey(const ValueKey('library-sort-menu')),
    );
    final filterSize = tester.getSize(
      find.byKey(const ValueKey('library-filter-menu')),
    );
    expect(layoutSize, sortSize);
    expect(sortSize, filterSize);
    expect(find.byTooltip('Сортировка: Недавно открытые'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('library-filter-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Избранное'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<BookLibraryFilter>, 'Избранное'),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.filter_alt), findsOneWidget);
    expect(find.byTooltip('Фильтр: Избранное'), findsOneWidget);
    // Import floats above the books; scanning sits in the app bar.
    expect(
      tester.widget(find.byKey(const ValueKey('import-book-button'))),
      isA<FloatingActionButton>(),
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byKey(const ValueKey('scan-device-books-button')),
      ),
      findsOneWidget,
    );

    await tester.binding.setSurfaceSize(null);
    controller.dispose();
  });

  testWidgets('system back closes an open library menu, not the library', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(seedManuscript: false),
    );
    await controller.load(preferredLanguage: 'ru');
    final navigator = GlobalKey<NavigatorState>();

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const SizedBox.shrink(),
      ),
    );
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => LiteriaLibraryPage(
            mode: LiteriaLibraryMode.reading,
            controller: controller,
            onPrimaryAction: () async {},
            onOpen: (_) async {},
            onDelete: (_) async {},
            onAbout: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const menuItems = {
      'library-sort-menu': 'По названию',
      'library-filter-menu': 'Прочитаны',
    };
    for (final MapEntry(key: menu, value: item) in menuItems.entries) {
      await tester.tap(find.byKey(ValueKey(menu)));
      await tester.pumpAndSettle();
      expect(find.text(item), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(item), findsNothing);
      expect(find.byKey(ValueKey(menu)), findsOneWidget);
    }

    await tester.binding.setSurfaceSize(null);
    controller.dispose();
  });

  testWidgets('manuscript menu does not expose reading-only status', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(seedManuscript: false),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.addProject();

    await tester.binding.setSurfaceSize(const Size(900, 800));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LiteriaLibraryPage(
          mode: LiteriaLibraryMode.manuscripts,
          controller: controller,
          onPrimaryAction: () async {},
          onOpen: (_) async {},
          onDelete: (_) async {},
          onAbout: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Название или глава'), findsOneWidget);
    expect(find.textContaining('Глав: 1'), findsOneWidget);
    expect(find.textContaining('Слов: 0'), findsOneWidget);
    expect(find.textContaining('Изменено:'), findsOneWidget);
    expect(find.byTooltip('Список'), findsOneWidget);
    expect(find.byTooltip('Сортировка: Недавно открытые'), findsOneWidget);
    expect(
      tester.widget(find.byKey(const ValueKey('create-manuscript-button'))),
      isA<FloatingActionButton>(),
    );
    expect(find.byKey(const ValueKey('library-filter-menu')), findsNothing);
    await tester.tap(find.byTooltip('Ещё'));
    await tester.pumpAndSettle();
    expect(find.text('Статус чтения'), findsNothing);

    await tester.binding.setSurfaceSize(null);
    controller.dispose();
  });
}
