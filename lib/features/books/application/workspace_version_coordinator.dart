import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_project_version.dart';
import 'package:dnevnik/features/books/domain/book_version_repository.dart';

class WorkspaceVersionCoordinator {
  const WorkspaceVersionCoordinator(this._repository);

  final BookVersionRepository _repository;

  Future<List<BookProjectVersion>> list(BookProject project) =>
      _repository.list(project.id);

  Future<BookProjectVersion> create(BookProject project, {String? label}) =>
      _repository.create(project: project, label: label);

  Future<void> delete(BookProject project, String versionId) =>
      _repository.delete(projectId: project.id, versionId: versionId);

  Future<BookProject> replaceFromExternalSource({
    required BookProject current,
    required BookProject source,
    required String safetyLabel,
  }) async {
    await _repository.create(project: current, label: safetyLabel);
    final copied = BookProject.fromJson(source.toJson());
    return BookProject(
      id: current.id,
      metadata: copied.metadata,
      sections: copied.sections,
      activeSectionId: copied.activeSectionId,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      layoutSettings: copied.layoutSettings,
      paragraphSettings: copied.paragraphSettings,
      readerSettings: copied.readerSettings,
      readerProgress: copied.readerProgress,
      readerAnnotations: copied.readerAnnotations,
      kind: current.kind,
      sourceFormat: current.sourceFormat,
      sourceFileName: current.sourceFileName,
      sourceStoredPath: current.sourceStoredPath,
      sourceFingerprint: current.sourceFingerprint,
      sourceExternalUri: current.sourceExternalUri,
      sourceFileSize: current.sourceFileSize,
      collectionName: current.collectionName,
      libraryState: current.libraryState,
      assets: current.assets,
      coverAssetId: current.coverAssetId,
    );
  }
}
