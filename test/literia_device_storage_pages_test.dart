import 'dart:typed_data';

import 'package:dnevnik/app/literia_book_storage_page.dart';
import 'package:dnevnik/app/literia_device_books_page.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_device_catalog.dart';
import 'package:dnevnik/features/books/application/book_import_coordinator.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_import_parser.dart';
import 'package:dnevnik/features/books/application/book_source_storage.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_scan_folder.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('device page scans remembered folders and selects a book', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(seedManuscript: false),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.addBookScanFolder(
      const BookScanFolder(uri: 'content://books', name: 'Книги'),
    );
    final catalog = _FakeCatalog();
    List<DeviceBookCandidate>? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: LiteriaDeviceBooksPage(
          controller: controller,
          catalog: catalog,
          onImport: (books) async {
            selected = books;
            return const BookImportBatchResult([]);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('sample.fb2'), findsOneWidget);
    expect(find.textContaining('Книги · 2.0 KB'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('device-book-content://book/1')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('import-selected-device-books')),
    );
    await tester.pumpAndSettle();

    expect(selected, hasLength(1));
    expect(selected!.single.uri, 'content://book/1');
  });

  testWidgets('storage page can remove only the stored original', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(seedManuscript: false),
    );
    await controller.load(preferredLanguage: 'ru');
    final parsed =
        BookImportParser.parse(
          BookImportFile(
            name: 'book.fb2',
            bytes: Uint8List.fromList(_minimalFb2.codeUnits),
          ),
        ).copyWith(
          sourceStoredPath: 'library/book/source.fb2',
          sourceFingerprint: 'fingerprint',
          sourceFileSize: 2048,
        );
    final imported = controller.addImportedBook(parsed);
    final storage = _RecordingSourceStorage();

    await tester.pumpWidget(
      MaterialApp(
        home: LiteriaBookStoragePage(
          controller: controller,
          sourceStorage: storage,
          deviceCatalog: const UnsupportedBookDeviceCatalog(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    final deleteOriginal = find.byKey(
      const ValueKey('delete-stored-originals'),
    );
    await tester.ensureVisible(deleteOriginal);
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(deleteOriginal).onPressed, isNotNull);
    await tester.tap(deleteOriginal);
    await tester.pumpAndSettle();
    expect(find.byType(BookLeatherDialog), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(BookLeatherDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pumpAndSettle();

    final retained = controller.projects.single;
    expect(retained.id, imported.id);
    expect(retained.sections, isNotEmpty);
    expect(retained.sourceStoredPath, isEmpty);
    expect(retained.sourceFingerprint, 'fingerprint');
    expect(storage.deletedOriginalIds, [imported.id]);
  });
}

class _FakeCatalog implements BookDeviceCatalogGateway {
  @override
  bool get supportsFolderScanning => true;

  @override
  Future<int?> availableBytes() async => 1000000;

  @override
  Future<BookScanFolder?> chooseFolder() async => null;

  @override
  Future<BookImportFile> materialize(DeviceBookCandidate candidate) async =>
      throw UnimplementedError();

  @override
  Future<void> releaseFolder(BookScanFolder folder) async {}

  @override
  Future<DeviceBookScanResult> scan(List<BookScanFolder> folders) async =>
      const DeviceBookScanResult(
        books: [
          DeviceBookCandidate(
            uri: 'content://book/1',
            name: 'sample.fb2',
            folderName: 'Книги',
            sizeBytes: 2048,
          ),
        ],
      );
}

class _RecordingSourceStorage extends EphemeralBookSourceStorage {
  final List<String> deletedOriginalIds = [];

  @override
  Future<void> deleteOriginal(BookProject project) async {
    deletedOriginalIds.add(project.id);
  }
}

const _minimalFb2 = '''<?xml version="1.0" encoding="utf-8"?>
<FictionBook xmlns="http://www.gribuser.ru/xml/fictionbook/2.0">
  <description><title-info><book-title>Книга</book-title></title-info></description>
  <body><section><title><p>Глава</p></title><p>Текст книги.</p></section></body>
</FictionBook>''';
