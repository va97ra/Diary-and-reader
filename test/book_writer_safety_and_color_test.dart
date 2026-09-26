import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/workspace_save_state.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_focus_mode_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/literia_test_navigation.dart';
import 'support/memory_author_workspace_repository.dart';

Future<(AuthorWorkspaceController, QuillController)> _openChapter(
  WidgetTester tester,
  String text,
) async {
  final controller = AuthorWorkspaceController(
    MemoryAuthorWorkspaceRepository(),
  );
  await controller.load(preferredLanguage: 'ru');
  controller.updateSectionContent([
    {'insert': '$text\n'},
  ]);
  await tester.binding.setSurfaceSize(const Size(390, 844));
  await tester.pumpWidget(AuthorStudioApp(controller: controller));
  await tester.pumpAndSettle();
  await openLastManuscript(tester, controller);
  final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
  return (controller, editor.controller);
}

void main() {
  testWidgets('deleted words wait in the trash and go back into the text', (
    tester,
  ) async {
    final (controller, editor) = await _openChapter(
      tester,
      'Мороз и солнце, день чудесный',
    );

    editor.replaceText(14, 15, '', const TextSelection.collapsed(offset: 14));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.byKey(const ValueKey('writer-more-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('writer-panel-trash')));
    await tester.pumpAndSettle();
    expect(find.text('«, день чудесный»'), findsOneWidget);

    await tester.tap(find.byTooltip('Ещё').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Вернуть в текст'));
    await tester.pumpAndSettle();

    expect(controller.activeProject!.textTrash, isEmpty);
    expect(
      richDocumentPlainText(controller.activeSection!.content),
      'Мороз и солнце, день чудесный\n',
    );
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('formatting colours the selected words', (tester) async {
    final (controller, editor) = await _openChapter(tester, 'Красное слово');
    editor.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 7),
      ChangeSource.local,
    );

    await tester.tap(find.byKey(const ValueKey('writer-formatting-action')));
    await tester.pumpAndSettle();
    final colorField = find.byKey(const ValueKey('formatting-text-color'));
    await tester.ensureVisible(colorField);
    await tester.pumpAndSettle();
    await tester.tap(colorField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Красный').last);
    await tester.pumpAndSettle();

    expect(controller.activeSection!.content.first, {
      'insert': 'Красное',
      'attributes': {'color': '#c62828'},
    });
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('the selection menu colours the selected words', (tester) async {
    final (controller, editor) = await _openChapter(tester, 'Синее слово');
    await tester.tap(find.byType(QuillEditor));
    await tester.pumpAndSettle();
    editor.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 5),
      ChangeSource.local,
    );
    await tester.pumpAndSettle();

    final editorState = tester.state<QuillRawEditorState>(
      find.byType(QuillRawEditor),
    );
    expect(editorState.showToolbar(), isTrue);
    await tester.pumpAndSettle();
    // The test font is wide, so the item waits in the overflow menu.
    if (find.text('Цвет').evaluate().isEmpty) {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Цвет'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Синий').last);
    await tester.pumpAndSettle();

    expect(controller.activeSection!.content.first, {
      'insert': 'Синее',
      'attributes': {'color': '#1565c0'},
    });
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('the exit button stands out on the dark focus bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: BookFocusModeBar(
            saveState: WorkspaceSaveState.saved,
            onRetrySave: () {},
            onExit: () {},
          ),
        ),
      ),
    );

    final icon = find.descendant(
      of: find.byKey(const ValueKey('editor-exit-focus-mode')),
      matching: find.byType(Icon),
    );
    final color = IconTheme.of(tester.element(icon)).color!;
    const bar = Color(0xFF141824);
    final contrast =
        (color.computeLuminance() + 0.05) / (bar.computeLuminance() + 0.05);
    expect(contrast, greaterThan(4.5));
  });
}
