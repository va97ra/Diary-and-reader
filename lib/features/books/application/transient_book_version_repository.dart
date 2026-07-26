import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_project_version.dart';
import 'package:dnevnik/features/books/domain/book_version_repository.dart';

class TransientBookVersionRepository implements BookVersionRepository {
  final List<BookProjectVersion> _versions = [];

  @override
  Future<List<BookProjectVersion>> list(String projectId) async {
    final versions =
        _versions.where((version) => version.projectId == projectId).toList()
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
    final version = BookProjectVersion(
      id: 'version-${now.microsecondsSinceEpoch}',
      projectId: project.id,
      createdAt: now,
      label: normalizedLabel == null || normalizedLabel.isEmpty
          ? null
          : normalizedLabel,
      project: BookProject.fromJson(project.toJson()),
    );
    _versions.add(version);
    return version;
  }

  @override
  Future<void> delete({
    required String projectId,
    required String versionId,
  }) async {
    _versions.removeWhere(
      (version) => version.projectId == projectId && version.id == versionId,
    );
  }
}
