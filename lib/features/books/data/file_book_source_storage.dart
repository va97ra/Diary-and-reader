import 'dart:convert';
import 'dart:io';

import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_source_storage.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';

class FileBookSourceStorage implements BookSourceStorage {
  FileBookSourceStorage({required this.supportDirectory});

  final Directory supportDirectory;

  Directory get _libraryDirectory =>
      Directory('${supportDirectory.path}${Platform.pathSeparator}library');

  Directory get _temporaryDirectory =>
      Directory('${_libraryDirectory.path}${Platform.pathSeparator}.tmp');

  @override
  Future<StoredBookSource> store({
    required String projectId,
    required BookImportFile file,
  }) async {
    await _temporaryDirectory.create(recursive: true);
    final safeId = _safeSegment(projectId);
    final extension = _safeExtension(file.name);
    final relativePath = 'library/$safeId/source$extension';
    final destinationDirectory = Directory(
      '${_libraryDirectory.path}${Platform.pathSeparator}$safeId',
    );
    final pending = File(
      '${_temporaryDirectory.path}${Platform.pathSeparator}$safeId.pending',
    );
    await _deleteFileIfExists(pending);
    try {
      await pending.writeAsBytes(file.bytes, flush: true);
      await destinationDirectory.create(recursive: true);
      final destination = File(
        '${destinationDirectory.path}${Platform.pathSeparator}source$extension',
      );
      await _deleteFileIfExists(destination);
      await pending.rename(destination.path);
      return StoredBookSource(
        relativePath: relativePath,
        sizeBytes: file.bytes.length,
      );
    } catch (_) {
      await _deleteFileIfExists(pending);
      rethrow;
    }
  }

  @override
  Future<void> deleteOriginal(BookProject project) async {
    final file = _resolveRelative(project.sourceStoredPath);
    if (file != null) await _deleteFileIfExists(file);
    await _deleteDirectoryIfEmpty(_projectDirectory(project.id));
  }

  @override
  Future<void> deleteProjectFiles(BookProject project) async {
    final source = _resolveRelative(project.sourceStoredPath);
    final sourceDirectory = source?.parent;
    if (sourceDirectory != null && await sourceDirectory.exists()) {
      await sourceDirectory.delete(recursive: true);
    }
    final directory = _projectDirectory(project.id);
    if (directory.path != sourceDirectory?.path && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  @override
  Future<BookStorageOverview> inspect(
    Iterable<BookProject> projects, {
    int? availableBytes,
  }) async {
    final entries = <BookStorageEntry>[];
    for (final project in projects.where((item) => item.isReadOnly)) {
      final processed = utf8.encode(jsonEncode(project.toJson())).length;
      final original = _resolveRelative(project.sourceStoredPath);
      final exists = original != null && await original.exists();
      final originalBytes = exists ? (await original.stat()).size : 0;
      entries.add(
        BookStorageEntry(
          project: project,
          processedBytes: processed,
          originalBytes: originalBytes,
          hasStoredOriginal: exists,
        ),
      );
    }
    return BookStorageOverview(
      entries: entries,
      processedBytes: entries.fold(0, (sum, item) => sum + item.processedBytes),
      originalBytes: entries.fold(0, (sum, item) => sum + item.originalBytes),
      availableBytes: availableBytes,
    );
  }

  @override
  Future<void> cleanup(Iterable<BookProject> projects) async {
    if (await _temporaryDirectory.exists()) {
      await _temporaryDirectory.delete(recursive: true);
    }
    if (!await _libraryDirectory.exists()) return;
    final retained = projects
        .where((project) => project.sourceStoredPath.isNotEmpty)
        .map((project) => project.sourceStoredPath.split('/'))
        .where((segments) => segments.length >= 3)
        .map((segments) => segments[1])
        .toSet();
    await for (final entity in _libraryDirectory.list()) {
      if (entity is! Directory || entity.path == _temporaryDirectory.path) {
        continue;
      }
      final name = entity.uri.pathSegments
          .where((segment) => segment.isNotEmpty)
          .lastOrNull;
      if (name != null && !retained.contains(name)) {
        await entity.delete(recursive: true);
      }
    }
  }

  Directory _projectDirectory(String projectId) => Directory(
    '${_libraryDirectory.path}${Platform.pathSeparator}${_safeSegment(projectId)}',
  );

  File? _resolveRelative(String relativePath) {
    if (relativePath.isEmpty || relativePath.contains('..')) return null;
    final normalized = relativePath.replaceAll('/', Platform.pathSeparator);
    if (!normalized.startsWith('library${Platform.pathSeparator}')) return null;
    return File('${supportDirectory.path}${Platform.pathSeparator}$normalized');
  }

  String _safeSegment(String input) =>
      input.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  String _safeExtension(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.fb2.zip')) return '.fb2.zip';
    if (lower.endsWith('.epub')) return '.epub';
    if (lower.endsWith('.fb2')) return '.fb2';
    if (lower.endsWith('.txt')) return '.txt';
    if (lower.endsWith('.rtf')) return '.rtf';
    if (lower.endsWith('.docx')) return '.docx';
    if (lower.endsWith('.mobi')) return '.mobi';
    if (lower.endsWith('.doc')) return '.doc';
    if (lower.endsWith('.chm')) return '.chm';
    if (lower.endsWith('.zip')) return '.zip';
    return '.book';
  }

  Future<void> _deleteFileIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }

  Future<void> _deleteDirectoryIfEmpty(Directory directory) async {
    if (!await directory.exists()) return;
    if (await directory.list().isEmpty) await directory.delete();
  }
}
