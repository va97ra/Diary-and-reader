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
  final directPreview = find.byKey(const ValueKey('writer-panel-preview'));
  if (directPreview.evaluate().isEmpty) {
    await tester.tap(find.byKey(const ValueKey('writer-more-menu')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const ValueKey('writer-panel-preview')));
  await tester.pumpAndSettle();
}
