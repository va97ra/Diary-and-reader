import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class BookExportFileSaver {
  Future<bool> save({
    required BookExportArtifact artifact,
    required String bookTitle,
  });
}

class BookExportFileService implements BookExportFileSaver {
  const BookExportFileService();

  static const _androidChannel = MethodChannel('literia/book_files');

  @override
  Future<bool> save({
    required BookExportArtifact artifact,
    required String bookTitle,
  }) async {
    final fileName = '${_safeName(bookTitle)}.${artifact.extension}';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _androidChannel.invokeMethod<bool>('saveTextFile', {
            'fileName': fileName,
            'mimeType': artifact.mimeType,
            'bytes': artifact.bytes,
          }) ??
          false;
    }
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
