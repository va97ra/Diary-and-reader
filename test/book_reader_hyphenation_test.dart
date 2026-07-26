import 'package:dnevnik/features/books/application/book_reader_hyphenation.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Russian hyphenation preserves original text and offsets', () async {
    final source = <Map<String, dynamic>>[
      {
        'insert': 'Автоматическое преобразование последовательности.\n',
        'attributes': {'bold': true},
      },
    ];
    final hyphenation = await BookReaderHyphenation.forLanguage('ru');
    final displayed = hyphenation.apply(source);
    final displayedText = richDocumentPlainText(displayed.document);
    final originalText = richDocumentPlainText(source);

    expect(displayedText, contains('\u00ad'));
    expect(displayedText.replaceAll('\u00ad', ''), originalText);
    expect(displayed.document.single['attributes'], {'bold': true});
    for (var offset = 0; offset <= originalText.length; offset++) {
      expect(
        displayed.displayToOriginal(displayed.originalToDisplay(offset)),
        offset,
      );
    }
  });

  test('Identity display keeps rich document and offset lengths unchanged', () {
    final source = <Map<String, dynamic>>[
      {'insert': 'Текст '},
      {
        'insert': 'с оформлением',
        'attributes': {'italic': true},
      },
      {
        'insert': {'image': 'asset://cover'},
      },
      {'insert': '\n'},
    ];
    final displayed = BookReaderHyphenation.identity(source);

    expect(displayed.document, source);
    expect(displayed.originalLength, displayed.displayLength);
    for (var offset = 0; offset <= displayed.originalLength; offset++) {
      expect(displayed.originalToDisplay(offset), offset);
      expect(displayed.displayToOriginal(offset), offset);
    }
  });

  test('English hyphenation keeps an existing soft hyphen stable', () async {
    const original = 'Extraordinary inter\u00adnational representation.\n';
    final source = <Map<String, dynamic>>[
      {'insert': original},
    ];
    final hyphenation = await BookReaderHyphenation.forLanguage('en');
    final displayed = hyphenation.apply(source);
    final displayedText = richDocumentPlainText(displayed.document);

    expect(
      displayedText.replaceAll('\u00ad', ''),
      original.replaceAll('\u00ad', ''),
    );
    expect(displayedText, isNot(contains('\u00ad\u00ad')));
    for (var offset = 0; offset <= original.length; offset++) {
      expect(
        displayed.displayToOriginal(displayed.originalToDisplay(offset)),
        offset,
      );
    }
  });

  test('background hyphenation preserves the synchronous result', () async {
    const source = <Map<String, dynamic>>[
      {'insert': 'Литературное произведение и повествование.\n'},
    ];
    final hyphenation = await BookReaderHyphenation.forLanguage('ru');

    final background = await hyphenation.applyInBackground(source);
    final synchronous = hyphenation.apply(source);

    expect(background.document, synchronous.document);
    expect(background.originalLength, synchronous.originalLength);
    expect(background.displayLength, synchronous.displayLength);
  });
}
