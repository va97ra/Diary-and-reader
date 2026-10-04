import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/literia_test_navigation.dart';
import 'support/memory_author_workspace_repository.dart';

Future<QuillController> _selectFirstWord(WidgetTester tester) async {
  final controller = AuthorWorkspaceController(
    MemoryAuthorWorkspaceRepository(),
  );
  await controller.load(preferredLanguage: 'ru');
  controller.updateSectionContent([
    {'insert': 'Слово за словом пишется книга.\n'},
  ]);
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(AuthorStudioApp(controller: controller));
  await tester.pumpAndSettle();
  await openLastManuscript(tester, controller);

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
}
