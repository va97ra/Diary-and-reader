import 'package:crypto/crypto.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_cover_thumbnail.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_import_parser.dart';
import 'package:dnevnik/features/books/application/book_source_storage.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:flutter/foundation.dart';

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
  }) => importStream(
    Stream<BookImportFile>.fromIterable(files),
    availableBytes: availableBytes,
  );

  Future<BookImportBatchResult> importStream(
    Stream<BookImportFile> files, {
    int? availableBytes,
  }) async {
    final results = <BookImportItemResult>[];
    final successful = <({int resultIndex, BookProject project})>[];
    var remainingBytes = availableBytes;
    final previousActiveProjectId = controller.activeProject?.id;
    final previousLastReadingId = controller.appPreferences.lastReadingId;
    await for (final file in files) {
      _PreparedBookImport prepared;
      try {
        prepared = await compute(
          _prepareBookImport,
          file,
          debugLabel: 'prepare-book-import',
        );
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
            project.isReadOnly &&
            (project.sourceFingerprint == fingerprint ||
                _sameSource(project, file)),
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
      BookProject? imported;

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
          sourceModifiedMillis: file.sourceModifiedMillis,
        );
        imported = controller.addImportedBook(parsed);
        final resultIndex = results.length;
        results.add(
          BookImportItemResult(fileName: file.name, project: imported),
        );
        successful.add((resultIndex: resultIndex, project: imported));
        if (remainingBytes != null) remainingBytes -= stored.sizeBytes;
      } on Exception {
        if (imported != null) {
          await _rollbackFailedImport(
            imported: imported,
            parsed: parsed,
            previousActiveProjectId: previousActiveProjectId,
            previousLastReadingId: previousLastReadingId,
          );
        } else {
          await _deleteFailedImportFiles(parsed);
        }
        results.add(
          BookImportItemResult(
            fileName: file.name,
            failure: BookImportItemFailure.storage,
          ),
        );
      }
    }
    if (successful.isNotEmpty && !await controller.flushWithResult()) {
      for (final item in successful.reversed) {
        controller.rollbackImportedBook(
          item.project.id,
          activeProjectId: previousActiveProjectId,
          lastReadingId: previousLastReadingId,
        );
        await _deleteFailedImportFiles(item.project);
        results[item.resultIndex] = BookImportItemResult(
          fileName: results[item.resultIndex].fileName,
          failure: BookImportItemFailure.storage,
        );
      }
      await controller.flush();
    }
    return BookImportBatchResult(List.unmodifiable(results));
  }

  Future<void> _rollbackFailedImport({
    required BookProject imported,
    required BookProject parsed,
    required String? previousActiveProjectId,
    required String? previousLastReadingId,
  }) async {
    controller.rollbackImportedBook(
      imported.id,
      activeProjectId: previousActiveProjectId,
      lastReadingId: previousLastReadingId,
    );
    await controller.flush();
    await _deleteFailedImportFiles(parsed);
  }

  Future<void> _deleteFailedImportFiles(BookProject project) async {
    try {
      await sourceStorage.deleteProjectFiles(project);
    } on Exception {
      // The import has already failed; cleanup must not abort the batch.
    }
  }
}

_PreparedBookImport _prepareBookImport(BookImportFile file) =>
    _PreparedBookImport(
      fingerprint: sha256.convert(file.bytes).toString(),
      project: BookCoverThumbnail.compact(BookImportParser.parseCatalog(file)),
    );

bool _sameSource(BookProject project, BookImportFile file) =>
    file.sourceUri.isNotEmpty &&
    project.sourceExternalUri == file.sourceUri &&
    project.sourceFileSize == file.effectiveSizeBytes &&
    project.sourceModifiedMillis == file.sourceModifiedMillis;

class _PreparedBookImport {
  const _PreparedBookImport({required this.fingerprint, required this.project});

  final String fingerprint;
  final BookProject project;
}
