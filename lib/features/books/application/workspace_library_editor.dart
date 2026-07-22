import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_scan_folder.dart';
import 'package:dnevnik/features/books/domain/literia_app_preferences.dart';

abstract final class WorkspaceLibraryEditor {
  static BookProject importedCopy(
    BookProject project, {
    required Iterable<String> existingIds,
    required BookReaderSettings readerSettings,
  }) {
    if (project.kind != BookProjectKind.importedBook ||
        project.sections.isEmpty) {
      throw ArgumentError.value(project, 'project', 'Invalid imported book');
    }
    final id = existingIds.contains(project.id)
        ? 'imported-${DateTime.now().microsecondsSinceEpoch}'
        : project.id;
    return BookProject(
      id: id,
      metadata: project.metadata,
      sections: project.sections,
      activeSectionId: project.activeSectionId,
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
      layoutSettings: project.layoutSettings,
      paragraphSettings: project.paragraphSettings,
      readerSettings: readerSettings,
      readerProgress: project.readerProgress,
      readerAnnotations: project.readerAnnotations,
      kind: BookProjectKind.importedBook,
      sourceFormat: project.sourceFormat,
      sourceFileName: project.sourceFileName,
      sourceStoredPath: project.sourceStoredPath,
      sourceFingerprint: project.sourceFingerprint,
      sourceExternalUri: project.sourceExternalUri,
      sourceFileSize: project.sourceFileSize,
      collectionName: project.collectionName,
      assets: project.assets,
      coverAssetId: project.coverAssetId,
    );
  }

  static BookProject updateSource(
    BookProject project, {
    required String storedPath,
    required String fingerprint,
    required String externalUri,
    required int fileSize,
  }) => project.copyWith(
    sourceStoredPath: storedPath,
    sourceFingerprint: fingerprint,
    sourceExternalUri: externalUri,
    sourceFileSize: fileSize,
  );

  static BookProject clearStoredSource(BookProject project) =>
      project.copyWith(clearStoredSource: true);

  static BookProject updateCollection(
    BookProject project,
    String collectionName,
  ) => project.copyWith(
    collectionName: collectionName.trim(),
    updatedAt: DateTime.now(),
  );

  static LiteriaAppPreferences selectProject(
    LiteriaAppPreferences preferences,
    BookProject project,
  ) => project.isReadOnly
      ? preferences.copyWith(lastReadingId: project.id)
      : preferences.copyWith(lastManuscriptId: project.id);

  static LiteriaAppPreferences removeProject(
    LiteriaAppPreferences preferences,
    String id,
  ) {
    var next = preferences;
    if (next.lastManuscriptId == id) {
      next = next.copyWith(clearLastManuscript: true);
    }
    if (next.lastReadingId == id) {
      next = next.copyWith(clearLastReading: true);
    }
    return next;
  }

  static LiteriaAppPreferences addScanFolder(
    LiteriaAppPreferences preferences,
    BookScanFolder folder,
  ) {
    final folders = [...preferences.bookScanFolders];
    final index = folders.indexWhere((item) => item.uri == folder.uri);
    if (index >= 0) {
      folders[index] = folder;
    } else {
      folders.add(folder);
    }
    return preferences.copyWith(bookScanFolders: folders);
  }

  static LiteriaAppPreferences removeScanFolder(
    LiteriaAppPreferences preferences,
    String uri,
  ) => preferences.copyWith(
    bookScanFolders: preferences.bookScanFolders
        .where((folder) => folder.uri != uri)
        .toList(),
  );
}
