import 'package:dnevnik/features/books/application/book_speech_segmenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts at the requested Cyrillic word and keeps source offsets', () {
    const text = 'Первая фраза. Вторая фраза!\nТретья.';
    final requested = text.indexOf('фраза!') + 2;
    final start = BookSpeechSegmenter.wordStart(text, requested);
    final segments = BookSpeechSegmenter.split(text, startOffset: start);

    expect(text.substring(start), startsWith('фраза!'));
    expect(segments.first.startOffset, start);
    expect(segments, hasLength(1));
    expect(segments.first.text, 'фраза!\nТретья.');
  });

  test('skips whitespace and safely splits a long sentence', () {
    final text = '   ${List.filled(40, 'слово').join(' ')}.';
    final segments = BookSpeechSegmenter.split(
      text,
      startOffset: 0,
      maximumLength: 40,
    );

    expect(segments, isNotEmpty);
    expect(segments.first.startOffset, 3);
    expect(segments.every((segment) => segment.text.length <= 40), isTrue);
  });

  test('groups sentences into long continuous utterances', () {
    final text = List.generate(
      30,
      (index) => 'Предложение номер $index.',
    ).join(' ');
    final segments = BookSpeechSegmenter.split(
      text,
      startOffset: 0,
      maximumLength: 180,
    );

    expect(segments.length, lessThan(10));
    expect(segments.every((segment) => segment.text.length <= 180), isTrue);
    expect(segments.first.text, contains('Предложение номер 5.'));
  });
}
