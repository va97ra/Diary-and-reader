import 'package:dnevnik/features/books/domain/rich_document.dart';

class ManuscriptStatistics {
  const ManuscriptStatistics({
    required this.words,
    required this.characters,
    required this.paragraphs,
  });

  factory ManuscriptStatistics.fromDocument(RichDocument document) {
    final text = document
        .map((operation) => operation['insert'])
        .whereType<String>()
        .join();
    final words = _wordPattern.allMatches(text).length;
    final characters = text.runes
        .where(
          (character) => character != _lineFeed && character != _carriageReturn,
        )
        .length;
    final paragraphs = text
        .split(RegExp(r'\r?\n'))
        .where((paragraph) => paragraph.trim().isNotEmpty)
        .length;

    return ManuscriptStatistics(
      words: words,
      characters: characters,
      paragraphs: paragraphs,
    );
  }

  static final _wordPattern = RegExp(
    r"[\p{L}\p{N}]+(?:[’'\-][\p{L}\p{N}]+)*",
    unicode: true,
  );
  static const _lineFeed = 10;
  static const _carriageReturn = 13;

  final int words;
  final int characters;
  final int paragraphs;

  double progressFor(int targetWords) {
    if (targetWords <= 0) return 0;
    return (words / targetWords).clamp(0, 1);
  }
}
