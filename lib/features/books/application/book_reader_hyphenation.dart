import 'dart:convert';
import 'dart:isolate';

import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:hyphenator_impure/hyphenator.dart';

class BookReaderDisplayDocument {
  const BookReaderDisplayDocument._(
    this.document,
    this._originalToDisplay,
    this._displayToOriginal,
  );

  final RichDocument document;
  final List<int> _originalToDisplay;
  final List<int> _displayToOriginal;

  int get originalLength => _originalToDisplay.length - 1;
  int get displayLength => _displayToOriginal.length - 1;

  int originalToDisplay(int offset) =>
      _originalToDisplay[offset.clamp(0, originalLength)];

  int displayToOriginal(int offset) =>
      _displayToOriginal[offset.clamp(0, displayLength)];
}

class BookReaderHyphenation {
  BookReaderHyphenation._({
    required this._patterns,
    required this._exceptions,
    required this._repairRussianEncoding,
  });

  static final _loaders = <String, Future<BookReaderHyphenation>>{};
  final List<String> _patterns;
  final List<String> _exceptions;
  final bool _repairRussianEncoding;
  late final Hyphenator _hyphenator = _createHyphenator(
    _patterns,
    _exceptions,
    repairRussianEncoding: _repairRussianEncoding,
  );

  static Future<BookReaderHyphenation> forLanguage(String languageCode) =>
      _loaders.putIfAbsent(languageCode == 'en' ? 'en' : 'ru', () async {
        final language = languageCode == 'en'
            ? DefaultResourceLoaderLanguage.enUs
            : DefaultResourceLoaderLanguage.ru;
        final loadedResource = await DefaultResourceLoader.load(language);
        return BookReaderHyphenation._(
          patterns: loadedResource.patternsStrings.toList(growable: false),
          exceptions: loadedResource.exceptionsStrings.toList(growable: false),
          repairRussianEncoding: language == DefaultResourceLoaderLanguage.ru,
        );
      });

  static BookReaderDisplayDocument identity(RichDocument source) =>
      _build(source, (text) => text);

  BookReaderDisplayDocument apply(RichDocument source) =>
      _build(source, _hyphenator.hyphenate);

  Future<BookReaderDisplayDocument> applyInBackground(RichDocument source) {
    final patterns = _patterns;
    final exceptions = _exceptions;
    final repairRussianEncoding = _repairRussianEncoding;
    return Isolate.run(() {
      final hyphenator = _createHyphenator(
        patterns,
        exceptions,
        repairRussianEncoding: repairRussianEncoding,
      );
      return _build(source, hyphenator.hyphenate);
    });
  }

  static BookReaderDisplayDocument _build(
    RichDocument source,
    String Function(String text) transform,
  ) {
    final document = <Map<String, dynamic>>[];
    final originalToDisplay = <int>[0];
    final displayToOriginal = <int>[0];
    var originalOffset = 0;
    var displayOffset = 0;

    for (final operation in source) {
      final copy = Map<String, dynamic>.from(operation);
      final insert = operation['insert'];
      if (insert is! String) {
        document.add(copy);
        originalOffset++;
        displayOffset++;
        originalToDisplay.add(displayOffset);
        displayToOriginal.add(originalOffset);
        continue;
      }

      final displayed = transform(insert);
      copy['insert'] = displayed;
      document.add(copy);
      var localOriginal = 0;
      for (var index = 0; index < displayed.length; index++) {
        final character = displayed[index];
        final isInsertedSoftHyphen =
            character == '\u00ad' &&
            (localOriginal >= insert.length ||
                insert[localOriginal] != '\u00ad');
        displayOffset++;
        if (isInsertedSoftHyphen) {
          displayToOriginal.add(originalOffset);
          originalToDisplay[originalOffset] = displayOffset;
          continue;
        }
        localOriginal++;
        originalOffset++;
        displayToOriginal.add(originalOffset);
        originalToDisplay.add(displayOffset);
      }
    }

    return BookReaderDisplayDocument._(
      document,
      originalToDisplay,
      displayToOriginal,
    );
  }
}

Hyphenator _createHyphenator(
  List<String> patterns,
  List<String> exceptions, {
  required bool repairRussianEncoding,
}) {
  final stored = _StoredHyphenationResource(patterns, exceptions);
  final resource = repairRussianEncoding
      ? _RepairedRussianResource(stored)
      : stored;
  return Hyphenator(resource: resource, minWordLength: 7, minLetterCount: 3);
}

class _StoredHyphenationResource implements ResourceLoader {
  const _StoredHyphenationResource(
    this.patternsStrings,
    this.exceptionsStrings,
  );

  @override
  final Iterable<String> patternsStrings;

  @override
  final Iterable<String> exceptionsStrings;
}

/// The bundled Russian TeX file in `hyphenator_impure` is UTF-8 text that was
/// accidentally encoded a second time through Windows-1252. Repairing it here
/// keeps only the small RU/EN pattern assets while preserving TeX-quality
/// hyphenation.
class _RepairedRussianResource implements ResourceLoader {
  _RepairedRussianResource(ResourceLoader source)
    : patternsStrings = source.patternsStrings.map(_repairWindows1252Utf8),
      exceptionsStrings = source.exceptionsStrings.map(_repairWindows1252Utf8);

  @override
  final Iterable<String> patternsStrings;

  @override
  final Iterable<String> exceptionsStrings;
}

String _repairWindows1252Utf8(String value) {
  final bytes = <int>[];
  for (final rune in value.runes) {
    if (rune <= 0xff) {
      bytes.add(rune);
      continue;
    }
    final byte = _windows1252Bytes[rune];
    if (byte == null) return value;
    bytes.add(byte);
  }
  return utf8.decode(bytes);
}

const _windows1252Bytes = <int, int>{
  0x20ac: 0x80,
  0x201a: 0x82,
  0x0192: 0x83,
  0x201e: 0x84,
  0x2026: 0x85,
  0x2020: 0x86,
  0x2021: 0x87,
  0x02c6: 0x88,
  0x2030: 0x89,
  0x0160: 0x8a,
  0x2039: 0x8b,
  0x0152: 0x8c,
  0x017d: 0x8e,
  0x2018: 0x91,
  0x2019: 0x92,
  0x201c: 0x93,
  0x201d: 0x94,
  0x2022: 0x95,
  0x2013: 0x96,
  0x2014: 0x97,
  0x02dc: 0x98,
  0x2122: 0x99,
  0x0161: 0x9a,
  0x203a: 0x9b,
  0x0153: 0x9c,
  0x017e: 0x9e,
  0x0178: 0x9f,
};
