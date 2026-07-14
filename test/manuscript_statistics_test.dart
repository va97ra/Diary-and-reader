import 'package:dnevnik/features/books/domain/manuscript_statistics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('counts Russian, English and hyphenated words', () {
    final statistics = ManuscriptStatistics.fromDocument([
      {'insert': 'Привет, мир!\nHello-world 42\n\n'},
    ]);

    expect(statistics.words, 4);
    expect(statistics.characters, 'Привет, мир!Hello-world 42'.runes.length);
    expect(statistics.paragraphs, 2);
  });

  test('ignores embeds and clamps target progress', () {
    final statistics = ManuscriptStatistics.fromDocument([
      {'insert': 'Один два\n'},
      {
        'insert': {'image': 'cover.png'},
      },
    ]);

    expect(statistics.words, 2);
    expect(statistics.progressFor(1), 1);
    expect(statistics.progressFor(0), 0);
  });
}
