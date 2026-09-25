import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/literia_test_navigation.dart';
import 'support/memory_author_workspace_repository.dart';

Future<AuthorWorkspaceController> _openFormatting(WidgetTester tester) async {
  final controller = AuthorWorkspaceController(
    MemoryAuthorWorkspaceRepository(),
  );
  await controller.load(preferredLanguage: 'ru');
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(AuthorStudioApp(controller: controller));
  await tester.pumpAndSettle();
  await openLastManuscript(tester, controller);
  await tester.tap(find.byKey(const ValueKey('writer-formatting-action')));
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('formatting goes from the words to the whole book', (
    tester,
  ) async {
    await _openFormatting(tester);

    double top(String key) => tester.getTopLeft(find.byKey(ValueKey(key))).dy;
    expect(
      top('formatting-text-section'),
      lessThan(top('formatting-paragraph-section')),
    );
    expect(
      top('formatting-paragraph-section'),
      lessThan(top('formatting-insert-section')),
    );
    expect(
      top('formatting-insert-section'),
      lessThan(top('formatting-manuscript-section')),
    );
    expect(
      find.text('Выделите слова или поставьте курсор в нужный абзац'),
      findsOneWidget,
    );
    // The paragraph type belongs to the paragraph.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('formatting-paragraph-section')),
        matching: find.byKey(const ValueKey('paragraph-style-selector')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('formatting leaves out tools a book does not need', (
    tester,
  ) async {
    await _openFormatting(tester);

    final attributes = tester
        .widgetList<QuillToolbarToggleStyleButton>(
          find.byType(QuillToolbarToggleStyleButton),
        )
        .map((button) => button.attribute.key)
        .toSet();
    expect(attributes, containsAll(['bold', 'italic', 'underline', 'strike']));
    for (final unwanted in <Attribute<dynamic>>[
      Attribute.codeBlock,
      Attribute.inlineCode,
      Attribute.blockQuote,
      Attribute.subscript,
      Attribute.superscript,
    ]) {
      expect(attributes, isNot(contains(unwanted.key)));
    }
    expect(find.byType(QuillToolbarToggleCheckListButton), findsNothing);
    expect(find.byType(QuillToolbarLinkStyleButton), findsNothing);
    // Pictures come from the same gallery-or-clipboard choice as the
    // Picture button, so there is no separate clipboard button.
    expect(find.byKey(const ValueKey('paste-book-image-button')), findsNothing);
  });

  testWidgets('the whole book spacings are drop-downs on one line', (
    tester,
  ) async {
    final controller = await _openFormatting(tester);
    final projectId = controller.activeProject!.id;
    final manuscript = find.byKey(
      const ValueKey('formatting-manuscript-section'),
    );
    await tester.ensureVisible(manuscript);
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: manuscript, matching: find.byType(TextField)),
      findsNothing,
    );
    final spacings = [
      find.byKey(ValueKey('$projectId-paragraph-indent')),
      find.byKey(ValueKey('$projectId-spacing-before')),
      find.byKey(ValueKey('$projectId-spacing-after')),
    ];
    final line = tester.getCenter(spacings.first).dy;
    for (final spacing in spacings) {
      expect(tester.getCenter(spacing).dy, line);
    }
    expect(find.text('Красная строка'), findsOneWidget);

    await tester.tap(spacings[1]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('6 пт').last);
    await tester.pumpAndSettle();

    expect(controller.activeProject!.paragraphSettings.spacingBeforePt, 6);
    expect(tester.takeException(), isNull);
  });
}
