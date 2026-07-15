import 'dart:convert';

import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_project_version.dart';
import 'package:dnevnik/features/books/domain/book_version_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesBookVersionRepository implements BookVersionRepository {
  const PreferencesBookVersionRepository(this.preferences);

  static const storageKey = 'author-studio-book-versions-v1';
  static const maxVersionsPerProject = 5;

  final SharedPreferences preferences;

  @override
  Future<List<BookProjectVersion>> list(String projectId) async {
    final versions =
        _readAll().where((version) => version.projectId == projectId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return versions;
  }

  @override
  Future<BookProjectVersion> create({
    required BookProject project,
    String? label,
  }) async {
    final now = DateTime.now().toUtc();
    final normalizedLabel = label?.trim();
    final created = BookProjectVersion(
      id: 'version-${now.microsecondsSinceEpoch}',
      projectId: project.id,
      createdAt: now,
      label: normalizedLabel == null || normalizedLabel.isEmpty
          ? null
          : normalizedLabel,
      project: BookProject.fromJson(project.toJson()),
    );
    final all = _readAll();
    final currentProject =
        all.where((version) => version.projectId == project.id).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final otherProjects = all
        .where((version) => version.projectId != project.id)
        .toList();
    final retained = [
      created,
      ...currentProject,
    ].take(maxVersionsPerProject).toList();
    await _writeAll([...otherProjects, ...retained]);
    return created;
  }

  @override
  Future<void> delete({required String projectId, required String versionId}) =>
      _writeAll(
        _readAll()
            .where(
              (version) =>
                  version.projectId != projectId || version.id != versionId,
            )
            .toList(),
      );

  List<BookProjectVersion> _readAll() {
    final encoded = preferences.getString(storageKey);
    if (encoded == null) return [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return [];
      final versions = <BookProjectVersion>[];
      for (final value in decoded.whereType<Map>()) {
        try {
          versions.add(
            BookProjectVersion.fromJson(Map<String, dynamic>.from(value)),
          );
        } on FormatException {
          // Keep other valid snapshots when one browser entry is damaged.
        }
      }
      return versions;
    } on Object {
      return [];
    }
  }

  Future<void> _writeAll(List<BookProjectVersion> versions) =>
      preferences.setString(
        storageKey,
        jsonEncode(versions.map((version) => version.toJson()).toList()),
      );
}
