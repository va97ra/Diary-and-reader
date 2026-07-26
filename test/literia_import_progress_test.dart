import 'dart:async';
import 'dart:io';

import 'package:dnevnik/app/literia_home_shell.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_source_storage.dart';
import 'package:dnevnik/features/books/data/book_import_file_service.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/literia_test_navigation.dart';
import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('opens only one file picker while an import is pending', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(seedManuscript: false),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.markOnboardingSeen();
    final gateway = _DeferredBookGateway();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LiteriaHomeShell(
          controller: controller,
          importFileGateway: gateway,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Читать').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Загрузить книги'));
    await tester.tap(find.text('Загрузить книги'));
    await tester.pump();

    expect(gateway.openCount, 1);

    gateway.cancel();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    controller.dispose();
  });

  testWidgets('shows progress while an imported book is being stored', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(seedManuscript: false),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.markOnboardingSeen();
    final file = BookImportFile(
      name: 'sample.fb2',
      bytes: File('test/fixtures/import_sample.fb2').readAsBytesSync(),
    );
    final storage = _DeferredBookSourceStorage();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LiteriaHomeShell(
          controller: controller,
          importFileGateway: _SingleBookGateway(file),
          sourceStorage: storage,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Читать').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Загрузить книги'));
    await tester.pump();
    await pumpUntilCondition(tester, () => storage.storeStarted);

    expect(storage.storeStarted, isTrue);
    expect(
      find.text('Книга обрабатывается и добавляется в библиотеку…'),
      findsOneWidget,
    );

    storage.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text('Книга обрабатывается и добавляется в библиотеку…'),
      findsNothing,
    );
    expect(
      controller.projects.where((project) => project.isReadOnly),
      hasLength(1),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    controller.dispose();
  });
}

class _DeferredBookGateway implements BookImportFileGateway {
  final Completer<BookImportFile?> _selection = Completer();
  int openCount = 0;

  void cancel() => _selection.complete();

  @override
  Future<BookImportFile?> open() {
    openCount++;
    return _selection.future;
  }
}

class _SingleBookGateway implements BookBatchImportFileGateway {
  const _SingleBookGateway(this.file);

  final BookImportFile file;

  @override
  Future<BookImportFile?> open() async => file;

  @override
  Future<List<BookImportFile>> openMany() async => [file];
}

class _DeferredBookSourceStorage implements BookSourceStorage {
  final Completer<StoredBookSource> _store = Completer();
  final Completer<void> _started = Completer();

  bool get storeStarted => _started.isCompleted;

  void complete() {
    _store.complete(const StoredBookSource(relativePath: '', sizeBytes: 1));
  }

  @override
  Future<StoredBookSource> store({
    required String projectId,
    required BookImportFile file,
  }) {
    _started.complete();
    return _store.future;
  }

  @override
  Future<void> cleanup(Iterable<BookProject> projects) async {}

  @override
  Future<void> deleteOriginal(BookProject project) async {}

  @override
  Future<void> deleteProjectFiles(BookProject project) async {}

  @override
  Future<BookStorageOverview> inspect(
    Iterable<BookProject> projects, {
    int? availableBytes,
  }) async => BookStorageOverview(
    entries: const [],
    processedBytes: 0,
    originalBytes: 0,
    availableBytes: availableBytes,
  );
}
