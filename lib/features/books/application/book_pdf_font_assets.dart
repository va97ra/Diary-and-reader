import 'dart:typed_data';

class BookPdfFontAssets {
  const BookPdfFontAssets({
    required this.regular,
    required this.bold,
    required this.italic,
    required this.boldItalic,
  });

  final Uint8List regular;
  final Uint8List bold;
  final Uint8List italic;
  final Uint8List boldItalic;
}

abstract interface class BookPdfFontLoader {
  Future<BookPdfFontAssets> load();
}
