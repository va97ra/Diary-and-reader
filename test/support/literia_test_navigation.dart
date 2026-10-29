import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpUntilCondition(
  WidgetTester tester,
  bool Function() condition, {
  int attempts = 200,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (condition()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int attempts = 200,
}) async {
  await pumpUntilCondition(
    tester,
    () => finder.evaluate().isNotEmpty,
    attempts: attempts,
  );
  expect(finder, findsWidgets);
}

Future<void> openLastManuscript(
  WidgetTester tester,
  AuthorWorkspaceController controller,
) async {
  await tester.tap(find.byKey(const ValueKey('home-write-tile')));
  await tester.pumpAndSettle();
  final project = controller.lastManuscript!;
  await tester.tap(find.byKey(ValueKey('literia-project-${project.id}')));
  await tester.pumpAndSettle();
}

Future<void> openReaderPreview(
  WidgetTester tester,
  AuthorWorkspaceController controller,
) async {
  await openLastManuscript(tester, controller);
  await tapWriterAction(tester, 'writer-panel-preview');
  await tester.pumpAndSettle();
}

/// Taps the middle of the page, which shows or hides the reader panels.
/// They float above the text and hide themselves once reading starts.
Future<void> toggleReaderPanels(WidgetTester tester) async {
  await tester.tapAt(
    tester.getCenter(
      find.byKey(const ValueKey('reader-reading-surface-listener')),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens a mobile scroll when needed; wide screens already show the tool.
Future<void> tapWriterAction(WidgetTester tester, String key) async {
  final action = find.byKey(ValueKey(key));
  if (find.byKey(const ValueKey('writer-context-bar')).evaluate().isNotEmpty) {
    final group = switch (key) {
      'writer-structure-action' ||
      'writer-new-page-action' ||
      'writer-new-chapter-action' => 'pages',
      'writer-formatting-action' || 'writer-panel-search' => 'text',
      'writer-picture-action' => 'insert',
      'writer-settings-action' => 'settings',
      _ => 'book',
    };
    if (find.byKey(ValueKey('writer-scroll-strip-$group')).evaluate().isEmpty) {
      await tester.tap(find.byKey(ValueKey('writer-scroll-$group')));
      await tester.pumpAndSettle();
    }
    await tester.scrollUntilVisible(
      action,
      100,
      scrollable: find.descendant(
        of: find.byKey(ValueKey('writer-scroll-actions-$group')),
        matching: find.byType(Scrollable),
      ),
    );
  } else {
    await tester.ensureVisible(action);
  }
  await tester.pumpAndSettle();
  await tester.tap(action);
}
