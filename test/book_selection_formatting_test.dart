import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_image_file.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_text_color_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/literia_test_navigation.dart';
import 'support/memory_author_workspace_repository.dart';

Future<void> _openChapter(WidgetTester tester, List<Object> content) async {
  final controller = AuthorWorkspaceController(
    MemoryAuthorWorkspaceRepository(),
  );
  await controller.load(preferredLanguage: 'ru');
  controller.updateSectionContent([
    for (final operation in content) operation as Map<String, dynamic>,
  ]);
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    AuthorStudioApp(
      controller: controller,
      clipboardImageGateway: const _EmptyClipboard(),
    ),
  );
  await tester.pumpAndSettle();
  await openLastManuscript(tester, controller);
}

/// The test machine has no system clipboard on every platform.
class _EmptyClipboard implements BookClipboardImageGateway {
  const _EmptyClipboard();

  @override
  Future<bool> hasImage() async => false;

  @override
  Future<BookImageFile?> read() async => null;
}

Future<QuillController> _selectFirstWord(
  WidgetTester tester, {
  List<Object> content = const [
    {'insert': 'Слово за словом пишется книга.\n'},
  ],
}) async {
  await _openChapter(tester, content);
  final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
  editor.focusNode.requestFocus();
  await tester.pump();
  editor.controller.updateSelection(
    const TextSelection(baseOffset: 0, extentOffset: 5),
    ChangeSource.local,
  );
  await tester.pump();
  tester
      .state<QuillRawEditorState>(
        find.byWidgetPredicate((widget) => widget is QuillRawEditor),
      )
      .showToolbar();
  await tester.pumpAndSettle();
  return editor.controller;
}

void main() {
  testWidgets('formatting appears right below the selected words', (
    tester,
  ) async {
    final controller = await _selectFirstWord(tester);
    final bar = find.byKey(const ValueKey('selection-formatting-bar'));

    expect(bar, findsOneWidget);
    // The colour moved from the copy menu into the bar.
    expect(find.text('Цвет'), findsNothing);
    final words = tester.getRect(find.byType(QuillEditor));
    expect(tester.getRect(bar).top, greaterThan(words.top));

    await tester.tap(find.byKey(const ValueKey('selection-format-bold')));
    await tester.pumpAndSettle();
    // The bar stays for the next change.
    await tester.tap(find.byKey(const ValueKey('selection-format-italic')));
    await tester.pumpAndSettle();

    final style = controller.getSelectionStyle().attributes;
    expect(style.containsKey(Attribute.bold.key), isTrue);
    expect(style.containsKey(Attribute.italic.key), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the colour button shows a rainbow, then the chosen colour', (
    tester,
  ) async {
    BoxDecoration bar(String hex) {
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byKey(ValueKey(hex)),
          matching: find.byType(Container),
        ),
      );
      return container.decoration! as BoxDecoration;
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            BookTextColorIcon(key: ValueKey(''), hex: ''),
            BookTextColorIcon(key: ValueKey('#1565c0'), hex: '#1565c0'),
          ],
        ),
      ),
    );

    expect(bar('').gradient, isA<LinearGradient>());
    expect(bar('#1565c0').color, const Color(0xFF1565C0));
    expect(bar('#1565c0').gradient, isNull);
  });

  testWidgets('clearing takes the words\' formatting, not the paragraph\'s', (
    tester,
  ) async {
    final controller = await _selectFirstWord(
      tester,
      content: const [
        {
          'insert': 'Слово',
          'attributes': {'bold': true, 'italic': true, 'color': '#1565c0'},
        },
        {'insert': ' за словом.'},
        {
          'insert': '\n',
          'attributes': {'align': 'justify'},
        },
      ],
    );

    await tester.tap(find.byKey(const ValueKey('selection-format-clear')));
    await tester.pumpAndSettle();

    final style = controller.getSelectionStyle().attributes;
    expect(style.containsKey(Attribute.bold.key), isFalse);
    expect(style.containsKey(Attribute.italic.key), isFalse);
    expect(style.containsKey(Attribute.color.key), isFalse);
    expect(style[Attribute.align.key]?.value, 'justify');
  });

  testWidgets(
    'on a computer a mouse selection shows the bar alone',
    (tester) async {
      await _openChapter(tester, const [
        {'insert': 'Слово за словом пишется книга.\n'},
      ]);
      final word =
          tester.getTopLeft(find.byType(QuillEditor)) + const Offset(16, 12);

      // A double click selects the word, as dragging over it does.
      await tester.tapAt(word, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(word, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('selection-formatting-bar')),
        findsOneWidget,
      );
      // No copy menu over the text: the keyboard and a right click have it.
      expect(find.text('Копировать'), findsNothing);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
