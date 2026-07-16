import 'dart:convert';
import 'dart:io';

import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_pdf_font_assets.dart';
import 'package:dnevnik/features/books/application/book_project_archive_codec.dart';
import 'package:dnevnik/features/books/data/book_export_file_service.dart';
import 'package:dnevnik/features/books/data/book_import_file_service.dart';
import 'package:dnevnik/features/books/data/book_project_backup_file_service.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(find.text('Рукопись'), findsOneWidget);
    expect(find.text('Свойства'), findsOneWidget);
    expect(find.byKey(const ValueKey('book-page-1')), findsOneWidget);
    expect(find.textContaining('A4 210×297 мм'), findsOneWidget);
    expect(find.text('Книжная'), findsOneWidget);
    expect(find.text('Альбомная'), findsOneWidget);
    expect(find.text('Слов: 0'), findsOneWidget);
    expect(find.text('Сохранено'), findsOneWidget);
    expect(find.text('Основной текст'), findsOneWidget);
    final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(editor.config.textSelectionThemeData?.cursorColor, AppTheme.ink);

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
    expect(
      find.byKey(const ValueKey('editor-bottom-navigation')),
      findsOneWidget,
    );
    expect(find.text('Редактор'), findsOneWidget);
    expect(find.textContaining('Лист A4 1 из 1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-a4-preview-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('editor-focus-mode-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('editor-exit-focus-mode')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('editor-bottom-navigation')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('book-editor-status-bar')), findsNothing);
    expect(find.byKey(const ValueKey('mobile-page-navigation')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('editor-exit-focus-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mobile-a4-preview-button')));
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

    await tester.tap(find.byKey(const ValueKey('mobile-a4-preview-button')));
    await _pumpUntil(tester, find.byKey(const ValueKey('book-page-1')));
    await tester.tap(find.byKey(const ValueKey('editor-focus-mode-button')));
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

    await tester.tap(find.byKey(const ValueKey('library-book-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Импортировать книгу для чтения'));
    await tester.pumpAndSettle();

    expect(gateway.openCount, 1);
    expect(find.byType(BookReaderPage), findsOneWidget);
    expect(find.byKey(const ValueKey('book-image-asset-1')), findsOneWidget);
    expect(controller.projects, hasLength(2));
    expect(controller.activeProject!.kind, BookProjectKind.importedBook);
    expect(
      repository.snapshot!.activeProject!.sourceFileName,
      'other-book.fb2',
    );

    Navigator.of(tester.element(find.byType(BookReaderPage))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('read-imported-book')), findsOneWidget);
    expect(find.text('Импортированная книга'), findsWidgets);
    expect(find.byKey(const ValueKey('book-cover-image')), findsWidgets);
    expect(find.text('Изображений: 1'), findsOneWidget);
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

    await tester.tap(find.byKey(const ValueKey('project-data-menu')));
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

    await tester.tap(find.byKey(const ValueKey('project-data-menu')));
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
    await tester.tap(find.byKey(const ValueKey('project-data-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Восстановить из файла'));
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
  final directButton = find.byKey(const ValueKey('export-book-button'));
  if (directButton.evaluate().isNotEmpty) {
    await tester.tap(directButton);
  } else {
    await tester.tap(find.byKey(const ValueKey('mobile-workspace-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Экспорт книги'));
  }
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
