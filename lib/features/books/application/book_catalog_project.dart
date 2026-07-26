import 'package:dnevnik/features/books/application/book_cover_thumbnail.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reading_progress.dart';

abstract final class BookCatalogProject {
  static BookProject compact(BookProject project) {
    if (!project.isReadOnly || project.isCatalogOnly) return project;
    final optimized = BookCoverThumbnail.compact(project);
    final cover = optimized.coverAsset;
    return optimized.copyWith(
      sections: const [],
      clearActiveSection: true,
      assets: cover == null ? const [] : [cover],
      coverAssetId: cover?.id,
      clearCoverAsset: cover == null,
      catalogReadingProgress: bookReadingProgress(
        project.sections,
        project.readerProgress,
      ),
    );
  }

  static BookProject hydrate({
    required BookProject catalog,
    required BookProject content,
  }) {
    final requestedSectionId = catalog.readerProgress.sectionId;
    final activeSectionId =
        content.sections.any((section) => section.id == requestedSectionId)
        ? requestedSectionId
        : content.sections.firstOrNull?.id;
    return BookProject(
      id: catalog.id,
      metadata: catalog.metadata,
      sections: content.sections,
      activeSectionId: activeSectionId,
      createdAt: catalog.createdAt,
      updatedAt: catalog.updatedAt,
      layoutSettings: catalog.layoutSettings,
      paragraphSettings: content.paragraphSettings,
      readerSettings: catalog.readerSettings,
      readerProgress: catalog.readerProgress.copyWith(
        sectionId: activeSectionId,
        clearSection: activeSectionId == null,
      ),
      readerAnnotations: catalog.readerAnnotations,
      kind: BookProjectKind.importedBook,
      sourceFormat: catalog.sourceFormat,
      sourceFileName: catalog.sourceFileName,
      sourceStoredPath: catalog.sourceStoredPath,
      sourceFingerprint: catalog.sourceFingerprint,
      sourceExternalUri: catalog.sourceExternalUri,
      sourceFileSize: catalog.sourceFileSize,
      sourceModifiedMillis: catalog.sourceModifiedMillis,
      catalogReadingProgress: catalog.catalogReadingProgress,
      collectionName: catalog.collectionName,
      libraryState: catalog.libraryState,
      writingState: catalog.writingState,
      assets: content.assets,
      coverAssetId: content.coverAssetId,
    );
  }
}
