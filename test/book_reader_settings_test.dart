import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reader settings round-trip independently from manuscript settings', () {
    const settings = BookReaderSettings(
      theme: BookReaderTheme.dark,
      fontFamily: 'Verdana',
      fontSize: 23,
      lineHeight: 1.8,
      contentWidth: 840,
    );

    expect(BookReaderSettings.fromJson(settings.toJson()), settings);
  });

  test('reader settings and progress reject unsafe persisted values', () {
    final settings = BookReaderSettings.fromJson({
      'theme': 'missing',
      'fontFamily': 'Missing Font',
      'fontSize': 200,
      'lineHeight': 0,
      'contentWidth': 10,
    });
    final progress = BookReaderProgress.fromJson({
      'sectionId': 'chapter-2',
      'sectionProgress': 3,
    });

    expect(settings.theme, BookReaderTheme.sepia);
    expect(settings.fontFamily, 'Georgia');
    expect(settings.fontSize, 32);
    expect(settings.lineHeight, 1.2);
    expect(settings.contentWidth, 480);
    expect(progress.sectionId, 'chapter-2');
    expect(progress.sectionProgress, 1);
  });
}
