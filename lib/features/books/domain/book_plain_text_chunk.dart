class BookPlainTextChunk {
  const BookPlainTextChunk({
    required this.text,
    required this.startOffset,
    required this.endOffset,
    this.heading,
  });

  final String text;
  final int startOffset;
  final int endOffset;
  final String? heading;
}

abstract final class BookPlainTextChunker {
  static const int targetCharacters = 24_000;
  static const int maximumCharacters = 32_000;
  static const int minimumCharactersBeforeHeading = 8_000;

  static final RegExp _headingLine = RegExp(
    r'^(?:chapter|book|part|volume|глава|часть|том)\b.{0,90}$',
    caseSensitive: false,
  );

  static List<BookPlainTextChunk> split(String text) {
    if (text.length <= maximumCharacters) {
      return [
        BookPlainTextChunk(
          text: text,
          startOffset: 0,
          endOffset: text.length,
          heading: _heading(text),
        ),
      ];
    }

    final chunks = <BookPlainTextChunk>[];
    var start = 0;
    while (start < text.length) {
      final remaining = text.length - start;
      final end = remaining <= maximumCharacters
          ? text.length
          : _splitOffset(text, start);
      final chunkText = text.substring(start, end);
      chunks.add(
        BookPlainTextChunk(
          text: chunkText,
          startOffset: start,
          endOffset: end,
          heading: _heading(chunkText),
        ),
      );
      start = end;
    }
    return chunks;
  }

  static int _splitOffset(String text, int start) {
    final target = (start + targetCharacters).clamp(start, text.length);
    final maximum = (start + maximumCharacters).clamp(start, text.length);
    final headingBoundary = _nextHeadingBoundary(
      text,
      start + minimumCharactersBeforeHeading,
      maximum,
    );
    if (headingBoundary != null) return headingBoundary;

    final paragraph = text.lastIndexOf('\n\n', maximum);
    if (paragraph >= target) return paragraph + 2;

    final line = text.lastIndexOf('\n', maximum);
    if (line >= target) return line + 1;

    final space = text.lastIndexOf(RegExp(r'\s'), maximum);
    return space >= target ? space + 1 : maximum;
  }

  static int? _nextHeadingBoundary(String text, int start, int end) {
    if (start >= end) return null;
    var lineStart = text.indexOf('\n', start);
    while (lineStart >= 0 && lineStart < end) {
      lineStart++;
      final lineEnd = text.indexOf('\n', lineStart);
      final boundedEnd = lineEnd < 0 ? text.length : lineEnd;
      if (boundedEnd > end) return null;
      final line = text.substring(lineStart, boundedEnd).trim();
      if (line.isNotEmpty &&
          _headingLine.hasMatch(line) &&
          _hasBlankLineBefore(text, lineStart)) {
        return lineStart;
      }
      lineStart = lineEnd;
    }
    return null;
  }

  static bool _hasBlankLineBefore(String text, int offset) {
    if (offset < 2) return true;
    return text[offset - 1] == '\n' && text[offset - 2] == '\n';
  }

  static String? _heading(String text) {
    for (final line in text.split('\n')) {
      final candidate = line.trim();
      if (candidate.isEmpty) continue;
      return _headingLine.hasMatch(candidate) ? candidate : null;
    }
    return null;
  }
}
