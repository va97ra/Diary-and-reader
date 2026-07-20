import 'dart:typed_data';

class BookImportFile {
  const BookImportFile({
    required this.name,
    required this.bytes,
    this.sourceUri = '',
  });

  final String name;
  final Uint8List bytes;
  final String sourceUri;
}

enum BookImportFailure { unsupportedFormat, invalidFile, noReadableText }

class BookImportException implements Exception {
  const BookImportException(this.failure, [this.details = '']);

  final BookImportFailure failure;
  final String details;

  @override
  String toString() => details.isEmpty
      ? 'BookImportException: ${failure.name}'
      : 'BookImportException: ${failure.name} ($details)';
}
