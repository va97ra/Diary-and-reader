import 'dart:convert';
import 'dart:io';

import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_project_version.dart';
import 'package:dnevnik/features/books/domain/book_version_repository.dart';

class FileBookVersionRepository implements BookVersionRepository {
  const FileBookVersionRepository({required this.directory});

  static const format = 'dnevnik-book-version';
  static const formatVersion = 1;

  final Directory directory;

  @override
  Future<List<BookProjectVersion>> list(String projectId) async {
    final projectDirectory = _projectDirectory(projectId);
    if (!await projectDirectory.exists()) return const [];
    final versions = <BookProjectVersion>[];
    await for (final entity in projectDirectory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final version = await _read(entity);
      if (version != null && version.projectId == projectId) {
        versions.add(version);
      }
    }
    versions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return versions;
  }

  @override
  Future<BookProjectVersion> create({
    required BookProject project,
    String? label,
  }) async {
    final now = DateTime.now().toUtc();
    final version = BookProjectVersion(
      id: 'version-${now.microsecondsSinceEpoch}',
      projectId: project.id,
      createdAt: now,
      label: _normalizedLabel(label),
      project: BookProject.fromJson(project.toJson()),
    );
    final projectDirectory = _projectDirectory(project.id);
    await projectDirectory.create(recursive: true);
    final destination = File(
      '${projectDirectory.path}${Platform.pathSeparator}${version.id}.json',
    );
    final pending = File('${destination.path}.pending');
    if (await pending.exists()) await pending.delete();
    await pending.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'format': format,
        'version': formatVersion,
        'data': version.toJson(),
      }),
      encoding: utf8,
      flush: true,
    );
    await pending.rename(destination.path);
    return version;
  }

  @override
  Future<void> delete({
    required String projectId,
    required String versionId,
  }) async {
    final file = File(
      '${_projectDirectory(projectId).path}${Platform.pathSeparator}'
      '${_safeComponent(versionId)}.json',
    );
    if (await file.exists()) await file.delete();
  }

  Future<BookProjectVersion?> _read(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString(encoding: utf8));
      if (decoded is! Map ||
          decoded['format'] != format ||
          decoded['version'] != formatVersion ||
          decoded['data'] is! Map) {
        return null;
      }
      return BookProjectVersion.fromJson(
        Map<String, dynamic>.from(decoded['data'] as Map),
      );
    } on FileSystemException {
      rethrow;
    } on Object {
      return null;
    }
  }

  Directory _projectDirectory(String projectId) => Directory(
    '${directory.path}${Platform.pathSeparator}${_safeComponent(projectId)}',
  );

  String _safeComponent(String value) {
    final safe = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '-');
    return safe.isEmpty ? 'unknown' : safe;
  }

  String? _normalizedLabel(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
