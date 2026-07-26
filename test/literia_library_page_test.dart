import 'package:dnevnik/app/literia_library_page.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
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
    expect(find.byKey(ValueKey('literia-project-${seed.id}')), findsOneWidget);
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

    expect(find.text('Название рукописи или главы'), findsOneWidget);
    expect(find.textContaining('Глав: 1'), findsOneWidget);
    expect(find.textContaining('Слов: 0'), findsOneWidget);
    expect(find.textContaining('Изменено:'), findsOneWidget);
    expect(find.textContaining('Режим просмотра:'), findsOneWidget);
    expect(find.textContaining('Сортировка:'), findsOneWidget);
    await tester.tap(find.byTooltip('Ещё'));
    await tester.pumpAndSettle();
    expect(find.text('Статус чтения'), findsNothing);

    await tester.binding.setSurfaceSize(null);
    controller.dispose();
  });
}
