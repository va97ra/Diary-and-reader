import 'package:dnevnik/features/books/application/book_speech_engine.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_document_view.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TTS continues with the next chapter', (tester) async {
    final first =
        BookSection.create(
          id: 'first',
          title: 'Первая',
          type: BookSectionType.chapter,
        ).copyWith(
          content: const [
            {'insert': 'Первый текст.\n'},
          ],
        );
    final second =
        BookSection.create(
          id: 'second',
          title: 'Вторая',
          type: BookSectionType.chapter,
        ).copyWith(
          content: const [
            {'insert': 'Второй текст.\n'},
          ],
        );
    final seed = BookProject.create(title: 'Книга', chapterTitle: 'Черновик');
    final project = seed.copyWith(
      sections: [first, second],
      activeSectionId: first.id,
      readerProgress: BookReaderProgress(sectionId: first.id),
    );
    final engine = _FakeSpeechEngine();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: BookReaderPage(
          project: project,
          readerSettings: const BookReaderSettings(),
          onSettingsChanged: (_) {},
          onProgressChanged: (_) {},
          onAnnotationsChanged: (_) {},
          speechEngine: engine,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reader-tts-action')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('reader-speech-controls')),
      findsOneWidget,
    );
    final reader = tester.widget<BookReaderTextFragment>(
      find.byType(BookReaderTextFragment).first,
    );
    reader.selectSpeechOffset(7);
    await tester.pumpAndSettle();

    expect(engine.spoken.single, startsWith('текст'));
    final highlightedReader = tester.widget<BookReaderTextFragment>(
      find.byType(BookReaderTextFragment).first,
    );
    expect(_hasBackground(highlightedReader.span), isTrue);
    await tester.tap(find.byKey(const ValueKey('reader-speech-pause-resume')));
    await tester.pump();
    expect(engine.pauseCount, 1);
    await tester.tap(find.byKey(const ValueKey('reader-speech-pause-resume')));
    await tester.pump();
    expect(engine.resumeCount, 1);
    await tester.tap(find.byKey(const ValueKey('reader-speech-faster')));
    await tester.pumpAndSettle();
    expect(engine.configuredRates.last, closeTo(0.55, 0.001));
    expect(engine.stopCount, 1);
    expect(engine.spoken, hasLength(2));
    engine.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(engine.spoken.last, contains('Второй текст'));
    expect(engine.configuredChapters, ['Первая', 'Первая', 'Вторая']);
  });
}

bool _hasBackground(InlineSpan span) {
  if (span.style?.backgroundColor != null) return true;
  return span is TextSpan && (span.children?.any(_hasBackground) ?? false);
}

class _FakeSpeechEngine implements BookSpeechEngine {
  final spoken = <String>[];
  final configuredChapters = <String>[];
  final configuredRates = <double>[];
  void Function()? _completion;
  int pauseCount = 0;
  int resumeCount = 0;
  int stopCount = 0;

  @override
  Future<void> configure({
    required String languageCode,
    required double rate,
    required double pitch,
    required String bookTitle,
    required String chapterTitle,
  }) async {
    configuredChapters.add(chapterTitle);
    configuredRates.add(rate);
  }

  @override
  void setCompletionHandler(void Function() handler) => _completion = handler;

  @override
  void setErrorHandler(void Function(String message) handler) {}

  @override
  Future<void> pause() async => pauseCount++;

  @override
  Future<void> resume() async => resumeCount++;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stopCount++;

  void complete() => _completion?.call();
}
