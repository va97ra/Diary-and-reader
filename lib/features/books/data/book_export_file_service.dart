import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:file_selector/file_selector.dart';

abstract interface class BookExportFileSaver {
  Future<bool> save({
    required BookExportArtifact artifact,
    required String bookTitle,
  });
}

class BookExportFileService implements BookExportFileSaver {
  const BookExportFileService();

  @override
  Future<bool> save({
    required BookExportArtifact artifact,
    required String bookTitle,
  }) async {
    final fileName = '${_safeName(bookTitle)}.${artifact.extension}';
    final location = await getSaveLocation(suggestedName: fileName);
    if (location == null) return false;

    final file = XFile.fromData(
      artifact.bytes,
      mimeType: artifact.mimeType,
      name: fileName,
    );
    await file.saveTo(location.path);
    return true;
  }

  String _safeName(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '-')
        .replaceAll(RegExp(r'\s+'), '-');
    return normalized.isEmpty ? 'book' : normalized;
  }
}
