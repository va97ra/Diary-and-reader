import 'package:dnevnik/features/books/presentation/widgets/book_adaptive_control_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a side panel grows by the cutout on its side', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          // A phone on its side with the camera on the right.
          data: MediaQuery.of(
            context,
          ).copyWith(padding: const EdgeInsets.only(right: 48)),
          child: child!,
        ),
        home: const BookAdaptiveControlShell(
          content: SizedBox.expand(),
          compactTopPanel: SizedBox(),
          compactBottomPanel: SizedBox(),
          wideStartPanel: SizedBox(),
          wideEndPanel: SizedBox(),
        ),
      ),
    );

    double width(String key) => tester.getSize(find.byKey(ValueKey(key))).width;
    expect(width('book-wide-start-panel'), 128);
    expect(width('book-wide-end-panel'), 128 + 48);
  });

  testWidgets('a long word gets smaller instead of breaking apart', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 40,
            child: BookWholeWordsText(
              'Оформление',
              maxLines: 2,
              style: TextStyle(fontSize: 10.5),
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Оформление'));
    expect(text.style!.fontSize, lessThan(10.5));
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('Оформление'),
    );
    // One line: the word stayed whole.
    expect(
      paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 10),
      ),
      hasLength(1),
    );
  });

  testWidgets('words that fit keep their size and wrap between words', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            child: BookWholeWordsText(
              'Поиск и замена',
              maxLines: 2,
              style: TextStyle(fontSize: 10.5),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('Поиск и замена')).style!.fontSize,
      10.5,
    );
  });
}
