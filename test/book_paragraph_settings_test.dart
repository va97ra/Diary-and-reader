import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classic preset has book-oriented paragraph measurements', () {
    final settings = BookParagraphSettings.forPreset(
      BookParagraphPreset.classic,
    );

    expect(settings.fontFamily, 'Georgia');
    expect(settings.fontSizePt, 12);
    expect(settings.lineHeight, 1.35);
    expect(settings.paragraphIndentMm, 5);
    expect(settings.spacingAfterPt, 0);
  });

  test('custom values round-trip and remain within safe bounds', () {
    final settings = BookParagraphSettings.fromJson({
      'preset': 'custom',
      'fontFamily': 'Arial',
      'fontSizePt': 200,
      'lineHeight': 0.5,
      'paragraphIndentMm': 8,
      'spacingBeforePt': 6,
      'spacingAfterPt': 12,
    });
    final restored = BookParagraphSettings.fromJson(settings.toJson());

    expect(restored.fontFamily, 'Arial');
    expect(restored.fontSizePt, 36);
    expect(restored.lineHeight, 1);
    expect(restored.paragraphIndentMm, 8);
    expect(restored.spacingBeforePt, 6);
    expect(restored.spacingAfterPt, 12);
  });

  test('unknown fonts fall back to Georgia', () {
    final settings = BookParagraphSettings.fromJson({
      'fontFamily': 'Missing Font',
    });

    expect(settings.fontFamily, 'Georgia');
  });
}
