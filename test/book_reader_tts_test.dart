import 'dart:convert';

import 'package:dnevnik/features/books/application/book_speech_engine.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
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
    final reader = tester.widget<QuillEditor>(find.byType(QuillEditor).first);
    final handled = reader.config.onTapUp!(
      TapUpDetails(
        globalPosition: Offset.zero,
        kind: PointerDeviceKind.touch,
      ),
      (_) => const TextPosition(offset: 7),
    );
    expect(handled, isTrue);
    await tester.pumpAndSettle();

    expect(engine.spoken.single, startsWith('текст'));
    final highlightedReader = tester.widget<QuillEditor>(
      find.byType(QuillEditor).first,
    );
    expect(
      jsonEncode(highlightedReader.controller.document.toDelta().toJson()),
      contains('background'),
    );
    await tester.tap(find.byKey(const ValueKey('reader-speech-pause-resume')));
    await tester.pump();
    expect(engine.pauseCount, 1);
    await tester.tap(find.byKey(const ValueKey('reader-speech-pause-resume')));
    await tester.pump();
    expect(engine.resumeCount, 1);
    engine.complete();
    await tester.pumpAndSettle();
    expect(engine.spoken.last, contains('Второй текст'));
    expect(engine.configuredChapters, ['Первая', 'Вторая']);
  });
}

class _FakeSpeechEngine implements BookSpeechEngine {
  final spoken = <String>[];
  final configuredChapters = <String>[];
  void Function()? _completion;
  int pauseCount = 0;
  int resumeCount = 0;

  @override
  Future<void> configure({
    required String languageCode,
    required double rate,
    required double pitch,
    required String bookTitle,
    required String chapterTitle,
  }) async => configuredChapters.add(chapterTitle);

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
  Future<void> stop() async {}

  void complete() => _completion?.call();
}
