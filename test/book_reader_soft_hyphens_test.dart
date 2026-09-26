import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_document_model.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_soft_hyphens.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _style = TextStyle(
  inherit: false,
  fontFamily: 'FlutterTest',
  fontSize: 10,
  color: Color(0xFF000000),
);

List<BookReaderHyphenBreak> _breaks(String text, double width) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: _style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width);
  final breaks = bookReaderHyphenBreaks(painter, text);
  painter.dispose();
  return breaks;
}

void main() {
  test('finds a line broken inside a word at a soft hyphen', () {
    // Each test glyph is 10 px wide: "aaaa" fits in 60 px, the whole word
    // does not, so the line breaks at the soft hyphen.
    final breaks = _breaks('aaaa\u00adbbbb', 60);

    expect(breaks, hasLength(1));
    expect(breaks.single.offset, 4);
    expect(breaks.single.line.lineNumber, 0);
  });

  test('a line broken at a space or unbroken text needs no hyphen', () {
    expect(_breaks('aaaa bbbb', 60), isEmpty);
    expect(_breaks('aa\u00adbb', 200), isEmpty);
  });

  test('hyphenated text leaves room for the hanging hyphen', () {
    const block = BookReaderBlock(
      type: BookReaderBlockType.paragraph,
      runs: [BookReaderTextRun(text: 'text', sourceStart: 0, sourceEnd: 4)],
      sourceStart: 0,
      sourceEnd: 4,
    );
    final palette = BookReaderPalette.forTheme(BookReaderTheme.sepia);
    final plain = BookReaderTypography.block(
      block,
      const BookReaderSettings(),
      palette,
    );
    final hyphenated = BookReaderTypography.block(
      block,
      const BookReaderSettings(hyphenateWords: true),
      palette,
    );

    expect(
      hyphenated.rightInset - plain.rightInset,
      const BookReaderSettings().fontSize * bookReaderHyphenReserve,
    );
  });

  testWidgets('draws the hyphen the text engine leaves out', (tester) async {
    const span = TextSpan(text: 'aaaa\u00adbbbb', style: _style);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 63,
            child: BookReaderSoftHyphens(
              span: span,
              textAlign: TextAlign.left,
              textDirection: TextDirection.ltr,
              child: Text.rich(span),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byType(BookReaderSoftHyphens),
      paints
        ..paragraph()
        ..paragraph(),
    );
  });
}
