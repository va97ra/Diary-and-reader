import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_document_model.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_typography.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _verse = {
  'blockquote': true,
  'align': 'center',
  'bookParagraphStyle': 'verse',
};

void main() {
  test('lines of a poem stand together and the poem is spaced apart', () {
    final model = BookReaderDocumentParser.parse(const [
      {'insert': 'Before.\n'},
      {'insert': 'First line'},
      {'insert': '\n', 'attributes': _verse},
      {'insert': 'Second line'},
      {'insert': '\n', 'attributes': _verse},
      {'insert': '\n', 'attributes': _verse},
      {'insert': 'Third line'},
      {'insert': '\n', 'attributes': _verse},
      {'insert': 'After.\n'},
    ]);
    final verse = model.blocks
        .where((block) => block.type == BookReaderBlockType.verse)
        .toList();

    expect(verse, hasLength(4));
    expect(
      [for (final line in verse) (line.joinsPrevious, line.joinsNext)],
      [(false, true), (true, true), (true, true), (true, false)],
    );

    const settings = BookReaderSettings();
    final palette = BookReaderPalette.forTheme(BookReaderTheme.sepia);
    final first = BookReaderTypography.block(verse.first, settings, palette);
    final middle = BookReaderTypography.block(verse[1], settings, palette);
    final last = BookReaderTypography.block(verse.last, settings, palette);
    expect((first.topSpacing, first.bottomSpacing), (10.0, 0.0));
    expect((middle.topSpacing, middle.bottomSpacing), (0.0, 0.0));
    expect((last.topSpacing, last.bottomSpacing), (0.0, 10.0));
    expect(first.textStyle.fontStyle, FontStyle.italic);
    expect(first.textAlign, TextAlign.center);
  });

  test('a dark word colour is lightened only on a dark page', () {
    final run = BookReaderDocumentParser.parse(const [
      {
        'insert': 'Blue',
        'attributes': {'color': '#1565c0'},
      },
      {'insert': '\n'},
    ]).blocks.single.runs.single;
    const blue = Color(0xFF1565C0);

    Color colorOn(BookReaderTheme theme) {
      final ink = BookReaderPalette.forTheme(theme).ink;
      return BookReaderTypography.run(run, TextStyle(color: ink)).color!;
    }

    expect(colorOn(BookReaderTheme.sepia), blue);
    final onDark = colorOn(BookReaderTheme.dark);
    expect(onDark, isNot(blue));
    expect(onDark.computeLuminance(), greaterThanOrEqualTo(0.2));
  });
}
