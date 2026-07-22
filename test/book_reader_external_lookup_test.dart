import 'package:dnevnik/features/books/application/book_reader_external_lookup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds encoded dictionary translation and search links', () {
    final dictionary = BookReaderExternalLookup.uri(
      action: BookReaderLookupAction.dictionary,
      text: 'белый медведь',
      languageCode: 'ru',
    );
    final translation = BookReaderExternalLookup.uri(
      action: BookReaderLookupAction.translate,
      text: 'hello world',
      languageCode: 'en',
    );
    final search = BookReaderExternalLookup.uri(
      action: BookReaderLookupAction.webSearch,
      text: 'Literia reader',
      languageCode: 'ru',
    );

    expect(dictionary.host, 'ru.wiktionary.org');
    expect(dictionary.pathSegments.last, 'белый медведь');
    expect(translation.queryParameters['tl'], 'ru');
    expect(translation.queryParameters['text'], 'hello world');
    expect(search.queryParameters['q'], 'Literia reader');
  });
}
