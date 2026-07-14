import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('A4 landscape keeps physical proportions at 96 DPI', () {
    const format = BookPageFormat.a4Landscape;

    expect(format.widthMm, 297);
    expect(format.heightMm, 210);
    expect(format.width, closeTo(1122.52, 0.01));
    expect(format.height, closeTo(793.70, 0.01));
    expect(format.width / format.height, closeTo(297 / 210, 0.001));
  });

  test('A4 portrait swaps physical sides without changing the paper', () {
    const format = BookPageFormat.a4Portrait;

    expect(format.widthMm, 210);
    expect(format.heightMm, 297);
    expect(format.width / format.height, closeTo(210 / 297, 0.001));
  });

  test('typographic points convert independently from page zoom', () {
    expect(BookPageFormat.pointsToLogicalPixels(12), 16);
    expect(BookPageFormat.pointsToLogicalPixels(24), 32);
  });

  test('page stays at 100 percent when enough width is available', () {
    const format = BookPageFormat.a4Landscape;

    expect(format.scaleForWidth(1400), 1);
    expect(format.scaleForWidth(format.width / 2), closeTo(0.5, 0.001));
  });
}
