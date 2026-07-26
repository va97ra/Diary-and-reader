import 'dart:convert';

import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';

class StoredBookSource {
  const StoredBookSource({required this.relativePath, required this.sizeBytes});

  final String relativePath;
  final int sizeBytes;
}

class BookStorageEntry {
  const BookStorageEntry({
    required this.project,
    required this.processedBytes,
    required this.originalBytes,
    required this.hasStoredOriginal,
  });

  final BookProject project;
  final int processedBytes;
  final int originalBytes;
  final bool hasStoredOriginal;

  int get totalBytes => processedBytes + originalBytes;
}

class BookStorageOverview {
  const BookStorageOverview({
    required this.entries,
    required this.processedBytes,
    required this.originalBytes,
    this.availableBytes,
  });

  final List<BookStorageEntry> entries;
  final int processedBytes;
  final int originalBytes;
  final int? availableBytes;

  int get totalBytes => processedBytes + originalBytes;
}

abstract interface class BookSourceStorage {
  Future<StoredBookSource> store({
    required String projectId,
    required BookImportFile file,
  });

  Future<void> deleteOriginal(BookProject project);

  Future<void> deleteProjectFiles(BookProject project);

  Future<BookStorageOverview> inspect(
    Iterable<BookProject> projects, {
    int? availableBytes,
  });

  Future<void> cleanup(Iterable<BookProject> projects);
}

abstract interface class BookReadingCacheStorage {
  Future<BookImportFile?> loadOriginal(BookProject project);

  Future<BookProject?> loadProcessed(BookProject project);

  Future<void> storeProcessed(BookProject project, BookProject processed);

  Future<bool> hasOriginal(BookProject project);
}

class EphemeralBookSourceStorage
    implements BookSourceStorage, BookReadingCacheStorage {
  const EphemeralBookSourceStorage();

  static final Map<String, BookImportFile> _sources = {};
  static final Map<String, BookProject> _processed = {};

  @override
  Future<void> cleanup(Iterable<BookProject> projects) async {}

  @override
  Future<void> deleteOriginal(BookProject project) async {
    _sources.remove(project.id);
  }

  @override
  Future<void> deleteProjectFiles(BookProject project) async {
    _sources.remove(project.id);
    _processed.remove(project.id);
  }

  @override
  Future<bool> hasOriginal(BookProject project) async =>
      _sources.containsKey(project.id);

  @override
  Future<BookImportFile?> loadOriginal(BookProject project) async =>
      _sources[project.id];

  @override
  Future<BookProject?> loadProcessed(BookProject project) async =>
      _processed[project.id];

  @override
  Future<void> storeProcessed(
    BookProject project,
    BookProject processed,
  ) async {
    _processed[project.id] = processed;
  }

  @override
  Future<BookStorageOverview> inspect(
    Iterable<BookProject> projects, {
    int? availableBytes,
  }) async {
    final entries = projects.where((project) => project.isReadOnly).map((
      project,
    ) {
      final processed = utf8.encode(jsonEncode(project.toJson())).length;
      return BookStorageEntry(
        project: project,
        processedBytes: processed,
        originalBytes: project.sourceFileSize,
        hasStoredOriginal: project.sourceStoredPath.isNotEmpty,
      );
    }).toList();
    return BookStorageOverview(
      entries: entries,
      processedBytes: entries.fold(0, (sum, item) => sum + item.processedBytes),
      originalBytes: entries.fold(0, (sum, item) => sum + item.originalBytes),
      availableBytes: availableBytes,
    );
  }

  @override
  Future<StoredBookSource> store({
    required String projectId,
    required BookImportFile file,
  }) async {
    _sources[projectId] = file;
    return StoredBookSource(relativePath: '', sizeBytes: file.bytes.length);
  }
}
