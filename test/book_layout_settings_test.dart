import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults old books to portrait A4', () {
    final settings = BookLayoutSettings.fromJson(const {});

    expect(settings.paperSize, BookPaperSize.a4);
    expect(settings.orientation, BookPageOrientation.portrait);
    expect(settings.pageFormat.widthMm, 210);
    expect(settings.pageFormat.heightMm, 297);
  });

  test('persists landscape orientation and margins', () {
    const source = BookLayoutSettings(
      orientation: BookPageOrientation.landscape,
      marginLeftMm: 25,
    );

    final restored = BookLayoutSettings.fromJson(source.toJson());

    expect(restored.orientation, BookPageOrientation.landscape);
    expect(restored.marginLeftMm, 25);
    expect(restored.pageFormat.widthMm, 297);
  });
}
