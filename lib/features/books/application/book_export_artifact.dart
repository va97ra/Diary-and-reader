import 'dart:typed_data';

enum BookExportFormat { epub, pdf }

class BookExportArtifact {
  const BookExportArtifact({
    required this.bytes,
    required this.extension,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String extension;
  final String mimeType;
}
