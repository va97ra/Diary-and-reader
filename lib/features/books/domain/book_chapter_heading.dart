abstract final class BookChapterHeading {
  static final RegExp _pattern = RegExp(
    r'^(?:(?:глава|часть|книга|том|chapter|part|book|volume)\s+'
    r'(?:\d+|[ivxlcdm]+|[a-zа-яё-]+)(?:\s*[.:—–-]\s*.{0,72})?|'
    r'(?:пролог|эпилог|предисловие|послесловие|введение|заключение|'
    r'prologue|epilogue|foreword|afterword|introduction|conclusion)'
    r'(?:\s*[:—–-]\s*.{1,80})?)$',
    caseSensitive: false,
    unicode: true,
  );

  static bool isRecognized(String value) => _pattern.hasMatch(value.trim());
}
