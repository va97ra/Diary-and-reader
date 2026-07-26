import 'package:dnevnik/features/books/application/book_catalog_project.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_import_parser.dart';
import 'package:dnevnik/features/books/application/book_source_storage.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:flutter/foundation.dart';

class BookReadingSessionLoader {
  const BookReadingSessionLoader(this.sourceStorage);

  final BookSourceStorage sourceStorage;

  Future<BookProject> load(BookProject catalog) async {
    if (!catalog.isCatalogOnly) return catalog;
    final cacheStorage = sourceStorage is BookReadingCacheStorage
        ? sourceStorage as BookReadingCacheStorage
        : null;
    if (cacheStorage == null) {
      throw const BookImportException(
        BookImportFailure.invalidFile,
        'Reading cache storage is unavailable.',
      );
    }
    var content = await cacheStorage.loadProcessed(catalog);
    if (content == null) {
      final source = await cacheStorage.loadOriginal(catalog);
      if (source == null) {
        throw const BookImportException(
          BookImportFailure.invalidFile,
          'The stored source file is unavailable.',
        );
      }
      final parsed = await compute(_parseReadingSource, (
        file: source,
        timestamp: catalog.createdAt,
      ), debugLabel: 'open-book-content');
      await cacheStorage.storeProcessed(catalog, parsed);
      content = parsed;
    }
    final resolvedContent = content;
    if (resolvedContent.sections.isEmpty) {
      throw const BookImportException(BookImportFailure.noReadableText);
    }
    return BookCatalogProject.hydrate(
      catalog: catalog,
      content: resolvedContent,
    );
  }
}

BookProject _parseReadingSource(
  ({BookImportFile file, DateTime timestamp}) request,
) => BookImportParser.parse(request.file, now: request.timestamp);
