class BookSpeechSegment {
  const BookSpeechSegment({
    required this.startOffset,
    required this.endOffset,
    required this.text,
  });

  final int startOffset;
  final int endOffset;
  final String text;
}

abstract final class BookSpeechSegmenter {
  static List<BookSpeechSegment> split(
    String text, {
    required int startOffset,
    int maximumLength = 3500,
  }) {
    if (text.isEmpty) return const [];
    var start = startOffset.clamp(0, text.length);
    final output = <BookSpeechSegment>[];
    while (start < text.length) {
      while (start < text.length && _isWhitespace(text[start])) {
        start++;
      }
      if (start >= text.length) break;
      final limit = (start + maximumLength).clamp(start + 1, text.length);
      var end = limit;
      if (limit < text.length) {
        final preferredMinimum = start + (maximumLength * 0.6).round();
        for (var candidate = limit; candidate > preferredMinimum; candidate--) {
          if (_isSentenceBoundary(text, candidate)) {
            end = candidate;
            break;
          }
        }
        if (end == limit && !_isSentenceBoundary(text, end)) {
          final whitespace = text.lastIndexOf(RegExp(r'\s'), end - 1);
          if (whitespace > start) end = whitespace + 1;
        }
      }
      final spoken = text.substring(start, end).trim();
      if (spoken.isNotEmpty) {
        output.add(
          BookSpeechSegment(startOffset: start, endOffset: end, text: spoken),
        );
      }
      start = end;
    }
    return output;
  }

  static int wordStart(String text, int requestedOffset) {
    if (text.isEmpty) return 0;
    var offset = requestedOffset.clamp(0, text.length);
    if (offset == text.length) return offset;
    while (offset < text.length && _isBoundary(text[offset])) {
      offset++;
    }
    while (offset > 0 && !_isBoundary(text[offset - 1])) {
      offset--;
    }
    return offset;
  }

  static bool _isSentenceBoundary(String text, int end) {
    final previous = text[end - 1];
    if (previous == '\n') return true;
    if (!'.!?…'.contains(previous)) return false;
    return end >= text.length || _isWhitespace(text[end]);
  }

  static bool _isWhitespace(String value) => RegExp(r'\s').hasMatch(value);

  static bool _isBoundary(String value) =>
      RegExp(r'[\s.,!?;:…—–()\[\]{}«»"/\\]').hasMatch(value);
}
