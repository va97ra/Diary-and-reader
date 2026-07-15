import 'dart:math' as math;

class BookReaderTextRange {
  const BookReaderTextRange(this.start, this.end);

  final int start;
  final int end;
}

abstract final class BookReaderTextAnchor {
  static BookReaderTextRange resolve({
    required String text,
    required int startOffset,
    required int endOffset,
    required String excerpt,
    required double sectionProgress,
  }) {
    final start = startOffset.clamp(0, text.length);
    final end = endOffset.clamp(start, text.length);
    final target = excerpt.trim();
    if (target.isEmpty || text.isEmpty) return BookReaderTextRange(start, end);
    if (text.substring(start, end) == target) {
      return BookReaderTextRange(start, end);
    }

    final expected = (text.length * sectionProgress.clamp(0, 1)).round();
    var bestStart = -1;
    var bestDistance = 0x7fffffff;
    var searchFrom = 0;
    while (searchFrom <= text.length - target.length) {
      final found = text.indexOf(target, searchFrom);
      if (found < 0) break;
      final distance = (found - expected).abs();
      if (distance < bestDistance) {
        bestStart = found;
        bestDistance = distance;
      }
      searchFrom = found + math.max(1, target.length);
    }
    return bestStart < 0
        ? BookReaderTextRange(start, end)
        : BookReaderTextRange(bestStart, bestStart + target.length);
  }
}
