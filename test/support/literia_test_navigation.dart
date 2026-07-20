import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  await tester.tap(find.byKey(const ValueKey('writer-more-menu')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Предпросмотр книги'));
  await tester.pumpAndSettle();
}
