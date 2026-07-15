import 'package:dnevnik/features/books/application/book_pdf_font_assets.dart';
import 'package:flutter/services.dart';

class BookPdfAssetFontLoader implements BookPdfFontLoader {
  const BookPdfAssetFontLoader();

  @override
  Future<BookPdfFontAssets> load() async => BookPdfFontAssets(
    regular: await _bytes('assets/fonts/PTSerif-Regular.ttf'),
    bold: await _bytes('assets/fonts/PTSerif-Bold.ttf'),
    italic: await _bytes('assets/fonts/PTSerif-Italic.ttf'),
    boldItalic: await _bytes('assets/fonts/PTSerif-BoldItalic.ttf'),
  );

  Future<Uint8List> _bytes(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}
