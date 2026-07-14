import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/presentation/book_typography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts paragraph measurements for the editor canvas', () {
    final settings = BookParagraphSettings.forPreset(
      BookParagraphPreset.classic,
    );

    final paragraph = BookTypography.editorStyles(settings).paragraph!;

    expect(
      paragraph.horizontalSpacing.left,
      closeTo(BookPageFormat.millimetersToLogicalPixels(5), 0.001),
    );
    expect(paragraph.style.fontFamily, 'Georgia');
    expect(paragraph.style.height, 1.35);
    expect(paragraph.verticalSpacing.top, 0);
    expect(paragraph.verticalSpacing.bottom, 0);
  });
}
