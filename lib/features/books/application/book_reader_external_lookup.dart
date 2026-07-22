import 'package:url_launcher/url_launcher.dart';

enum BookReaderLookupAction { dictionary, translate, webSearch }

typedef BookReaderUriLauncher = Future<bool> Function(Uri uri);

abstract final class BookReaderExternalLookup {
  static Uri uri({
    required BookReaderLookupAction action,
    required String text,
    required String languageCode,
  }) {
    final normalized = text.trim();
    return switch (action) {
      BookReaderLookupAction.dictionary => Uri.https(
        languageCode == 'en' ? 'en.wiktionary.org' : 'ru.wiktionary.org',
        '/wiki/$normalized',
      ),
      BookReaderLookupAction.translate =>
        Uri.https('translate.google.com', '/', {
          'sl': 'auto',
          'tl': languageCode == 'en' ? 'ru' : 'en',
          'text': normalized,
          'op': 'translate',
        }),
      BookReaderLookupAction.webSearch => Uri.https(
        'www.google.com',
        '/search',
        {'q': normalized},
      ),
    };
  }
}

Future<bool> launchBookReaderUri(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
