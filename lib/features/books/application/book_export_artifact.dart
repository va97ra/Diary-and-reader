import 'dart:typed_data';

enum BookExportFormat { epub, fb2, fb2Zip, pdf, docx, html, markdown, txt }

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
