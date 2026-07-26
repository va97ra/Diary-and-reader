import 'package:dnevnik/features/books/domain/book_chapter_heading.dart';

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

  static List<BookPlainTextChunk> split(String text) {
    final headingOffsets = _chapterHeadingOffsets(text);
    if (headingOffsets.length >= 2) {
      final chunks = <BookPlainTextChunk>[];
      if (text.substring(0, headingOffsets.first).trim().isNotEmpty) {
        chunks.addAll(_splitRange(text, 0, headingOffsets.first));
      }
      for (var index = 0; index < headingOffsets.length; index++) {
        chunks.addAll(
          _splitRange(
            text,
            headingOffsets[index],
            index + 1 < headingOffsets.length
                ? headingOffsets[index + 1]
                : text.length,
          ),
        );
      }
      return chunks;
    }
    return _splitRange(text, 0, text.length);
  }

  static List<BookPlainTextChunk> _splitRange(
    String source,
    int rangeStart,
    int rangeEnd,
  ) {
    final chunks = <BookPlainTextChunk>[];
    final text = source.substring(rangeStart, rangeEnd);
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
          startOffset: rangeStart + start,
          endOffset: rangeStart + end,
          heading: _heading(chunkText),
        ),
      );
      start = end;
    }
    return chunks;
  }

  static List<int> _chapterHeadingOffsets(String text) {
    final offsets = <int>[];
    var offset = 0;
    for (final line in text.split('\n')) {
      if (BookChapterHeading.isRecognized(line)) offsets.add(offset);
      offset += line.length + 1;
    }
    return offsets;
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
          BookChapterHeading.isRecognized(line) &&
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
      return BookChapterHeading.isRecognized(candidate) ? candidate : null;
    }
    return null;
  }
}
