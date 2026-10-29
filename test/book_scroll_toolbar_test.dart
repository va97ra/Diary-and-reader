import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/literia_test_navigation.dart';
import 'support/memory_author_workspace_repository.dart';

Future<AuthorWorkspaceController> _openWriter(
  WidgetTester tester, {
  double width = 390,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final controller = AuthorWorkspaceController(
    MemoryAuthorWorkspaceRepository(),
  );
  await controller.load(preferredLanguage: 'ru');
  controller.updateSectionContent([
    {'insert': 'До курсора и после него.\n'},
  ]);
  await tester.pumpWidget(AuthorStudioApp(controller: controller));
  await tester.pumpAndSettle();
  await openLastManuscript(tester, controller);
  return controller;
}

void main() {
  testWidgets('switching scrolls and Back keep the manuscript open', (
    tester,
  ) async {
    final controller = await _openWriter(tester);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('mobile-writing-editor')))
          .height,
      greaterThan(400),
    );
    final before = richDocumentPlainText(controller.activeSection!.content);
    final editorBounds = tester.getRect(
      find.byKey(const ValueKey('mobile-writing-editor')),
    );
    await tester.tap(find.byKey(const ValueKey('writer-scroll-pages')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('writer-new-page-action')),
      findsOneWidget,
    );
    final strip = tester.getRect(
      find.byKey(const ValueKey('writer-scroll-strip-pages')),
    );
    final handle = tester.getRect(
      find.byKey(const ValueKey('writer-scroll-pages')),
    );
    expect(strip.width, closeTo(handle.width, 0.01));
    expect(strip.left, closeTo(handle.left, 0.01));
    expect(strip.bottom, closeTo(handle.top, 0.01));
    expect(
      tester.getRect(find.byKey(const ValueKey('mobile-writing-editor'))),
      editorBounds,
    );
    expect(find.text('Новая страница'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('writer-scroll-book')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('writer-scroll-strip-pages')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('writer-scroll-strip-book')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('writer-scroll-strip-book')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('writer-context-bar')), findsOneWidget);
    expect(richDocumentPlainText(controller.activeSection!.content), before);
  });

  testWidgets(
    'scroll follows its handle above the keyboard and closes outside',
    (tester) async {
      await _openWriter(tester);
      tester.view.viewInsets = FakeViewPadding(
        bottom: 300 * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('writer-scroll-pages')));
      await tester.pumpAndSettle();
      final handle = tester.getRect(
        find.byKey(const ValueKey('writer-scroll-pages')),
      );
      final strip = tester.getRect(
        find.byKey(const ValueKey('writer-scroll-strip-pages')),
      );
      expect(handle.bottom, lessThanOrEqualTo(544));
      expect(strip.bottom, closeTo(handle.top, 0.01));
      await tester.tapAt(const Offset(280, 200));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('writer-scroll-strip-pages')),
        findsNothing,
      );
    },
  );

  testWidgets('new page inserts at the cursor and preserves surrounding text', (
    tester,
  ) async {
    final controller = await _openWriter(tester);
    final editor = tester
        .widget<QuillEditor>(find.byType(QuillEditor).first)
        .controller;
    editor.updateSelection(
      const TextSelection.collapsed(offset: 10),
      ChangeSource.local,
    );
    await tapWriterAction(tester, 'writer-new-page-action');
    await tester.pumpAndSettle();
    final content = controller.activeSection!.content;
    expect(
      content.any(
        (operation) =>
            operation['insert'] is Map &&
            richDocumentIsPageBreak(operation['insert'] as Map),
      ),
      isTrue,
    );
    final text = richDocumentPlainText(content);
    expect(text, contains('До курсора'));
    expect(text, contains(' и после него.'));
    expect(
      find.byKey(const ValueKey('writer-scroll-strip-pages')),
      findsNothing,
    );
    // The editor remains usable after inserting the break.
    final current = tester
        .widget<QuillEditor>(find.byType(QuillEditor).first)
        .controller;
    current.replaceText(current.selection.extentOffset, 0, 'Продолжение', null);
    await tester.pumpAndSettle();
    expect(
      richDocumentPlainText(controller.activeSection!.content),
      contains('Продолжение'),
    );
  });

  testWidgets(
    'all handles fit a narrow phone and large text without overflow',
    (tester) async {
      await _openWriter(tester, width: 320);
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      for (final id in ['pages', 'text', 'insert', 'settings', 'book']) {
        final handle = find.byKey(ValueKey('writer-scroll-$id'));
        expect(tester.getRect(handle).right, lessThanOrEqualTo(320));
        await tester.tap(handle);
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('writer-scroll-strip-$id')), findsOneWidget);
      }
    },
  );
}
