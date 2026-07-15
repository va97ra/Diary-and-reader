import 'dart:convert';
import 'dart:typed_data';

import 'package:dnevnik/features/books/application/book_reader_annotation_exporter.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';

abstract interface class BookReaderAnnotationFileSaver {
  Future<bool> save({
    required BookReaderAnnotationExport export,
    required String bookTitle,
  });
}

class BookReaderAnnotationFileService implements BookReaderAnnotationFileSaver {
  const BookReaderAnnotationFileService();

  @override
  Future<bool> save({
    required BookReaderAnnotationExport export,
    required String bookTitle,
  }) async {
    final timestamp = DateFormat('yyyy-MM-dd-HHmm').format(DateTime.now());
    final baseName = _safeName(bookTitle);
    final fileName = '$baseName-annotations-$timestamp.${export.extension}';
    final location = await getSaveLocation(suggestedName: fileName);
    if (location == null) return false;

    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(export.content)),
      mimeType: export.mimeType,
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
