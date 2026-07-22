import 'dart:convert';
import 'dart:io';

import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/application/book_image_file.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_pdf_font_assets.dart';
import 'package:dnevnik/features/books/application/book_project_archive_codec.dart';
import 'package:dnevnik/features/books/data/book_export_file_service.dart';
import 'package:dnevnik/features/books/data/book_import_file_service.dart';
import 'package:dnevnik/features/books/data/book_project_backup_file_service.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/literia_test_navigation.dart';
import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('shows manuscript and properties on desktop', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    expect(find.byKey(const ValueKey('writer-context-bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('editor-bottom-navigation')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('book-page-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('book-editor-status-bar')), findsNothing);
    expect(find.byKey(const ValueKey('writer-header-metrics')), findsOneWidget);
    expect(find.textContaining('Слов: 0 · Страница 1/1'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('writer-header-metrics')))
          .style
          ?.fontSize,
      11,
    );
    expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
    expect(find.text('Сохранено'), findsOneWidget);
    final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(editor.config.textSelectionThemeData?.cursorColor, AppTheme.ink);

    await tester.tap(find.byKey(const ValueKey('writer-settings-action')));
    await tester.pumpAndSettle();
    expect(find.text('Настройки рукописи'), findsOneWidget);
    expect(find.textContaining('A4 210×297 мм'), findsOneWidget);
    expect(find.text('Книжная'), findsOneWidget);
    expect(find.text('Альбомная'), findsOneWidget);
    await tester.ensureVisible(find.text('Альбомная'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Альбомная'));
    await tester.pumpAndSettle();
    expect(
      controller.activeProject!.layoutSettings.orientation,
      BookPageOrientation.landscape,
    );
    expect(find.textContaining('A4 297×210 мм'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('shows compact bottom navigation on mobile', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    final mobileContent = <Map<String, dynamic>>[
      {'insert': 'Абзац, набранный на смартфоне.\n'},
    ];
    controller.updateSectionContent(mobileContent);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    expect(find.byKey(const ValueKey('writer-context-bar')), findsOneWidget);
    expect(find.text('Оформление'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.text('Ещё'), findsOneWidget);
    final moreButtonSize = tester.getSize(
      find.byKey(const ValueKey('writer-more-menu')),
    );
    expect(moreButtonSize.width, greaterThanOrEqualTo(48));
    expect(moreButtonSize.height, greaterThanOrEqualTo(48));
    expect(find.textContaining('Лист A4 1 из 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('book-editor-status-bar')), findsNothing);
    final headerMetrics = tester.widget<Text>(
      find.byKey(const ValueKey('writer-header-metrics')),
    );
    expect(headerMetrics.data, '4 слов · 1/1');
    expect(headerMetrics.style?.fontSize, 9.5);
    expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
    expect(find.text('Сохранено'), findsOneWidget);
    final writerAppBar = tester.widget<AppBar>(
      find.byKey(const ValueKey('writer-app-bar')),
    );
    expect(writerAppBar.backgroundColor, AppTheme.surface);
    expect(
      tester
          .widget<Material>(find.byKey(const ValueKey('writer-context-bar')))
          .color,
      AppTheme.surface,
    );
    final chapterTitle = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('writer-section-title-action')),
        matching: find.text('Глава 1'),
      ),
    );
    expect(chapterTitle.style?.fontSize, 14);
    final writingSurface = find.byKey(const ValueKey('mobile-writing-editor'));
    final writingRect = tester.getRect(writingSurface);
    expect(writingRect.left, 0);
    expect(writingRect.width, 390);
    expect(tester.widget<ColoredBox>(writingSurface).color, AppTheme.paper);
    expect(
      tester
          .widget<Padding>(find.byKey(const ValueKey('mobile-writing-content')))
          .padding,
      const EdgeInsets.fromLTRB(20, 12, 20, 10),
    );
    expect(find.byType(TextField), findsNothing);
    expect(
      find.byKey(const ValueKey('mobile-a4-preview-button')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('writer-hide-panels-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('editor-exit-focus-mode')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
    expect(find.byKey(const ValueKey('writer-context-bar')), findsNothing);
    expect(find.byKey(const ValueKey('book-editor-status-bar')), findsNothing);
    expect(find.byKey(const ValueKey('mobile-page-navigation')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('editor-exit-focus-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('writer-settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('writer-a4-preview-action')));
    await _pumpUntil(tester, find.byKey(const ValueKey('book-page-1')));
    expect(find.textContaining('Точная разметка A4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-a4-page-preview')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('mobile-a4-edit-button')), findsOneWidget);

    final previewRect = tester.getRect(
      find.byKey(const ValueKey('book-page-1')),
    );
    expect(previewRect.width, greaterThan(340));

    await tester.tap(find.byKey(const ValueKey('mobile-a4-edit-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-writing-editor')), findsOneWidget);
    expect(find.byKey(const ValueKey('book-page-1')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('writer-settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('writer-a4-preview-action')));
    await _pumpUntil(tester, find.byKey(const ValueKey('book-page-1')));
    await tester.tap(find.byKey(const ValueKey('writer-hide-panels-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('editor-exit-focus-mode')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('book-page-1')), findsNothing);
    expect(find.byKey(const ValueKey('mobile-writing-editor')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('editor-exit-focus-mode')));
    await tester.pumpAndSettle();
    expect(
      jsonEncode(controller.activeSection!.content),
      jsonEncode(mobileContent),
    );
    expect(
      find.byKey(const ValueKey('mobile-page-navigation')),
      findsOneWidget,
    );

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'keeps autosave status visible on a tablet in both orientations',
    (tester) async {
      final controller = AuthorWorkspaceController(
        MemoryAuthorWorkspaceRepository(),
      );
      await controller.load(preferredLanguage: 'ru');
      await tester.binding.setSurfaceSize(const Size(800, 1280));
      await tester.pumpWidget(AuthorStudioApp(controller: controller));
      await tester.pumpAndSettle();
      await openLastManuscript(tester, controller);

      expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
      expect(find.text('Сохранено'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
      expect(find.text('Сохранено'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('renames a manuscript by tapping its title', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await tester.tap(find.byKey(const ValueKey('writer-book-title-action')));
    await tester.pumpAndSettle();
    expect(find.text('Название книги'), findsNWidgets(2));

    await tester.enterText(
      find.byKey(const ValueKey('writer-book-title-field')),
      'Моя первая книга',
    );
    await tester.tap(find.byKey(const ValueKey('writer-book-title-save')));
    await tester.pumpAndSettle();

    expect(controller.activeProject!.metadata.title, 'Моя первая книга');
    expect(find.text('Моя первая книга'), findsOneWidget);
    expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
    expect(find.text('Сохранено'), findsWidgets);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('renames and starts a chapter without a large mobile field', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('writer-section-title-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('writer-section-title-field')),
      'Встреча',
    );
    await tester.tap(find.byKey(const ValueKey('writer-section-title-save')));
    await tester.pumpAndSettle();
    expect(controller.activeSection!.title, 'Встреча');

    final sectionCount = controller.activeProject!.sections.length;
    await tester.tap(find.byKey(const ValueKey('writer-structure-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navigator-new-chapter')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('navigator-new-chapter')));
    await tester.pumpAndSettle();

    expect(controller.activeProject!.sections.length, sectionCount + 1);
    expect(controller.activeSection!.title, 'Новая глава');
    expect(find.byType(TextField), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('finds and replaces text across a mobile manuscript', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent([
      {'insert': 'Старый дом и ещё один дом.\n'},
    ]);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    await tester.tap(find.byKey(const ValueKey('writer-more-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Поиск и замена в рукописи'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('manuscript-search-field')),
      'дом',
    );
    await tester.pumpAndSettle();
    expect(find.text('Найдено совпадений: 2'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('manuscript-replacement-field')),
      'сад',
    );
    await tester.tap(find.byKey(const ValueKey('replace-all-button')));
    await tester.pumpAndSettle();

    expect(
      richDocumentPlainText(controller.activeSection!.content),
      'Старый сад и ещё один сад.\n',
    );
    expect(find.text('Выполнено замен: 2'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('inserts an image into a mobile manuscript', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent([
      {'insert': 'Текст должен сохраниться.\n'},
    ]);
    final imageGateway = _MemoryBookImageGateway(
      BookImageFile(
        name: 'pixel.png',
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, imageFileGateway: imageGateway),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    editor.controller.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 5),
      ChangeSource.local,
    );
    await tester.tap(find.byKey(const ValueKey('writer-formatting-action')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('insert-book-image-button')));
    await tester.pumpAndSettle();

    expect(imageGateway.openCount, 1);
    expect(controller.activeProject!.assets, hasLength(1));
    expect(
      jsonEncode(controller.activeSection!.content),
      contains('bookImage'),
    );
    expect(
      richDocumentPlainText(controller.activeSection!.content),
      'Текст должен сохраниться.\n',
    );
    expect(find.text('Изображение добавлено в рукопись'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('inserts a page break without deleting selected text', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent([
      {'insert': 'Текст должен сохраниться.\n'},
    ]);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    editor.controller.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 5),
      ChangeSource.local,
    );
    await tester.tap(find.byKey(const ValueKey('writer-formatting-action')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('insert-book-page-break-button')),
    );
    await tester.pumpAndSettle();

    expect(
      jsonEncode(controller.activeSection!.content),
      contains('bookPageBreak'),
    );
    expect(
      richDocumentPlainText(controller.activeSection!.content),
      'Текст должен сохраниться.\n',
    );
    expect(
      find.text('Следующий текст начнётся с новой страницы'),
      findsOneWidget,
    );

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('imports an FB2 into the library and opens it in the reader', (
    tester,
  ) async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');
    final gateway = _MemoryBookImportGateway(
      BookImportFile(
        name: 'other-book.fb2',
        bytes: File('test/fixtures/import_sample.fb2').readAsBytesSync(),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, importFileGateway: gateway),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-read-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-book-button')));
    await tester.pumpAndSettle();

    expect(gateway.openCount, 1);
    expect(find.byType(BookReaderPage), findsOneWidget);
    expect(find.byKey(const ValueKey('book-image-asset-1')), findsOneWidget);
    expect(controller.projects, hasLength(2));
    expect(controller.activeProject!.kind, BookProjectKind.importedBook);
    final importedProjectId = controller.activeProject!.id;
    expect(
      repository.snapshot!.activeProject!.sourceFileName,
      'other-book.fb2',
    );

    Navigator.of(tester.element(find.byType(BookReaderPage))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reading-library')), findsOneWidget);
    expect(
      find.byKey(ValueKey('literia-project-$importedProjectId')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('book-cover-image')), findsWidgets);
    expect(find.byType(QuillEditor), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('exports the active project as EPUB', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    final saver = _MemoryBookExportSaver();
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, exportFileSaver: saver),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await _openExportSheet(tester);
    expect(find.text('Экспорт книги'), findsOneWidget);
    expect(find.text('EPUB 3.3 (.epub)'), findsOneWidget);
    expect(find.text('Печатный PDF (.pdf)'), findsOneWidget);
    expect(find.text('Документ Word (.docx)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('export-book-epub')));
    await tester.pumpAndSettle();

    expect(saver.artifact?.extension, 'epub');
    expect(saver.artifact?.bytes, isNotEmpty);
    expect(saver.bookTitle, 'Новая книга');
    expect(find.text('Книга сохранена'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('exports the active project as DOCX', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    final saver = _MemoryBookExportSaver();
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, exportFileSaver: saver),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await _openExportSheet(tester);
    expect(find.byKey(const ValueKey('export-book-docx')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('export-book-docx')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-book-docx')));
    await tester.pumpAndSettle();

    expect(saver.artifact?.extension, 'docx');
    expect(saver.artifact?.mimeType, contains('wordprocessingml'));
    expect(saver.artifact?.bytes, isNotEmpty);
    expect(saver.bookTitle, 'Новая книга');
    expect(find.text('Книга сохранена'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('shows every export group and creates an archived FB2', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    final saver = _MemoryBookExportSaver();
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, exportFileSaver: saver),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await _openExportSheet(tester);
    expect(find.text('Для электронных читалок'), findsOneWidget);
    expect(find.text('Для печати и редактирования'), findsOneWidget);
    expect(find.text('Открытые текстовые форматы'), findsOneWidget);
    expect(find.byKey(const ValueKey('export-book-fb2')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-book-fb2-zip')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-book-html')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-book-markdown')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-book-txt')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('export-book-fb2-zip')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-book-fb2-zip')));
    await tester.pumpAndSettle();

    expect(saver.artifact?.extension, 'fb2.zip');
    expect(saver.artifact?.mimeType, 'application/zip');
    expect(saver.artifact?.bytes, isNotEmpty);
    expect(find.text('Книга сохранена'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('opens PDF preview and reports generation errors', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      AuthorStudioApp(
        controller: controller,
        pdfFontLoader: _FailingPdfFontLoader(),
      ),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await _openExportSheet(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('export-book-pdf')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-book-pdf')));
    await tester.pumpAndSettle();

    expect(find.text('Предварительный просмотр PDF'), findsOneWidget);
    expect(
      find.text('Не удалось создать предварительный просмотр PDF'),
      findsOneWidget,
    );
    expect(find.text('Повторить'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('creates a named snapshot from the project data menu', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await tester.tap(find.byKey(const ValueKey('writer-more-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('История версий'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Снимков пока нет'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('create-version-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('version-label-field')),
      'Перед финалом',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-create-version')));
    await tester.pumpAndSettle();

    expect(find.text('Перед финалом'), findsOneWidget);
    expect(await controller.listVersions(), hasLength(1));
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('exports and safely restores a portable project backup', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    final backupGateway = _MemoryProjectBackupGateway();
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, backupFileGateway: backupGateway),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await tester.tap(find.byKey(const ValueKey('writer-more-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить резервную копию'));
    await tester.pumpAndSettle();
    expect(backupGateway.savedArchive, isNotNull);
    expect(
      BookProjectArchiveCodec.decode(
        backupGateway.savedArchive!,
      ).metadata.title,
      'Новая книга',
    );

    final imported = controller.activeProject!.copyWith(
      metadata: const BookMetadata(title: 'Восстановленная книга'),
    );
    backupGateway.archiveToOpen = BookProjectArchiveCodec.encode(imported);
    await tester.tap(find.byKey(const ValueKey('writer-more-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Восстановить проект из резервной копии'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-project-restore')));
    await tester.pumpAndSettle();

    expect(controller.activeProject!.metadata.title, 'Восстановленная книга');
    expect(await controller.listVersions(), hasLength(1));
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('refreshes the editor content after version restore', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent(const <Map<String, dynamic>>[
      {'insert': 'Сохранённый вариант\n'},
    ]);
    final version = await controller.createVersion(label: 'Сохранённый');
    controller.updateSectionContent(const <Map<String, dynamic>>[
      {'insert': 'Заменяемый вариант\n'},
    ]);
    await controller.flush();

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    bool editorContains(String text) => tester
        .widgetList<QuillEditor>(find.byType(QuillEditor))
        .any(
          (editor) => editor.controller.document.toPlainText().contains(text),
        );
    expect(editorContains('Заменяемый вариант'), isTrue);

    await controller.restoreVersion(
      version!,
      safetyLabel: 'Перед восстановлением',
    );
    await tester.pumpAndSettle();

    expect(editorContains('Сохранённый вариант'), isTrue);
    expect(editorContains('Заменяемый вариант'), isFalse);
    await tester.binding.setSurfaceSize(null);
  });
}

Future<void> _openExportSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('writer-more-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Экспорт книги'));
  await tester.pumpAndSettle();
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

class _MemoryBookExportSaver implements BookExportFileSaver {
  BookExportArtifact? artifact;
  String? bookTitle;

  @override
  Future<bool> save({
    required BookExportArtifact artifact,
    required String bookTitle,
  }) async {
    this.artifact = artifact;
    this.bookTitle = bookTitle;
    return true;
  }
}

class _MemoryBookImageGateway implements BookImageFileGateway {
  _MemoryBookImageGateway(this.file);

  final BookImageFile? file;
  int openCount = 0;

  @override
  Future<BookImageFile?> open() async {
    openCount++;
    return file;
  }
}

class _MemoryBookImportGateway implements BookImportFileGateway {
  _MemoryBookImportGateway(this.file);

  final BookImportFile? file;
  int openCount = 0;

  @override
  Future<BookImportFile?> open() async {
    openCount++;
    return file;
  }
}

class _FailingPdfFontLoader implements BookPdfFontLoader {
  @override
  Future<BookPdfFontAssets> load() =>
      Future.error(const FormatException('Font test failure'));
}

class _MemoryProjectBackupGateway implements BookProjectBackupFileGateway {
  String? savedArchive;
  String? archiveToOpen;

  @override
  Future<String?> open() async => archiveToOpen;

  @override
  Future<bool> save({
    required String archive,
    required String bookTitle,
  }) async {
    savedArchive = archive;
    return true;
  }
}
