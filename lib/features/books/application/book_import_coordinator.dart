import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_import_parser.dart';
import 'package:dnevnik/features/books/application/book_source_storage.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';

enum BookImportItemFailure {
  duplicate,
  unsupportedFormat,
  conversionRequired,
  noReadableText,
  invalidFile,
  notEnoughSpace,
  storage,
}

class BookImportItemResult {
  const BookImportItemResult({
    required this.fileName,
    this.project,
    this.failure,
  });

  final String fileName;
  final BookProject? project;
  final BookImportItemFailure? failure;

  bool get succeeded => project != null;
}

class BookImportBatchResult {
  const BookImportBatchResult(this.items);

  final List<BookImportItemResult> items;

  List<BookProject> get imported => items
      .map((item) => item.project)
      .whereType<BookProject>()
      .toList(growable: false);

  int get duplicateCount => items
      .where((item) => item.failure == BookImportItemFailure.duplicate)
      .length;

  int get failedCount => items
      .where(
        (item) =>
            !item.succeeded && item.failure != BookImportItemFailure.duplicate,
      )
      .length;

  int get conversionRequiredCount => items
      .where((item) => item.failure == BookImportItemFailure.conversionRequired)
      .length;
}

class BookImportCoordinator {
  const BookImportCoordinator({
    required this.controller,
    required this.sourceStorage,
  });

  final AuthorWorkspaceController controller;
  final BookSourceStorage sourceStorage;

  Future<BookImportBatchResult> import(
    Iterable<BookImportFile> files, {
    int? availableBytes,
  }) async {
    final results = <BookImportItemResult>[];
    var remainingBytes = availableBytes;
    for (final file in files) {
      _PreparedBookImport prepared;
      try {
        prepared = await Isolate.run(() => _prepareBookImport(file));
      } on BookImportException catch (error) {
        results.add(
          BookImportItemResult(
            fileName: file.name,
            failure: switch (error.failure) {
              BookImportFailure.unsupportedFormat =>
                BookImportItemFailure.unsupportedFormat,
              BookImportFailure.conversionRequired =>
                BookImportItemFailure.conversionRequired,
              BookImportFailure.noReadableText =>
                BookImportItemFailure.noReadableText,
              BookImportFailure.invalidFile =>
                BookImportItemFailure.invalidFile,
            },
          ),
        );
        continue;
      } on Object {
        results.add(
          BookImportItemResult(
            fileName: file.name,
            failure: BookImportItemFailure.invalidFile,
          ),
        );
        continue;
      }
      final fingerprint = prepared.fingerprint;
      final duplicate = controller.projects.any(
        (project) =>
            project.isReadOnly && project.sourceFingerprint == fingerprint,
      );
      if (duplicate) {
        results.add(
          BookImportItemResult(
            fileName: file.name,
            failure: BookImportItemFailure.duplicate,
          ),
        );
        continue;
      }
      if (remainingBytes != null && file.bytes.length > remainingBytes) {
        results.add(
          BookImportItemResult(
            fileName: file.name,
            failure: BookImportItemFailure.notEnoughSpace,
          ),
        );
        continue;
      }

      var parsed = prepared.project;

      try {
        final stored = await sourceStorage.store(
          projectId: parsed.id,
          file: file,
        );
        parsed = parsed.copyWith(
          sourceStoredPath: stored.relativePath,
          sourceFingerprint: fingerprint,
          sourceExternalUri: file.sourceUri,
          sourceFileSize: stored.sizeBytes,
        );
        final imported = controller.addImportedBook(parsed);
        await controller.flush();
        results.add(
          BookImportItemResult(fileName: file.name, project: imported),
        );
        if (remainingBytes != null) remainingBytes -= stored.sizeBytes;
      } on Exception {
        await sourceStorage.deleteProjectFiles(parsed);
        results.add(
          BookImportItemResult(
            fileName: file.name,
            failure: BookImportItemFailure.storage,
          ),
        );
      }
    }
    return BookImportBatchResult(List.unmodifiable(results));
  }
}

_PreparedBookImport _prepareBookImport(BookImportFile file) =>
    _PreparedBookImport(
      fingerprint: sha256.convert(file.bytes).toString(),
      project: BookImportParser.parse(file),
    );

class _PreparedBookImport {
  const _PreparedBookImport({required this.fingerprint, required this.project});

  final String fingerprint;
  final BookProject project;
}
