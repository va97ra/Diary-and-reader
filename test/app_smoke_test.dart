import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/literia_test_navigation.dart';
import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('opens the new home without creating a test manuscript', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(seedManuscript: false),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-write-tile')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-read-tile')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-settings-tile')), findsOneWidget);
    expect(find.text('Новая книга'), findsNothing);
    expect(controller.projects, isEmpty);
  });

  testWidgets('new writer and reader never show legacy navigation', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    expect(find.byKey(const ValueKey('writer-context-bar')), findsNothing);
    expect(find.byKey(const ValueKey('writer-left-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('writer-right-panel')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('editor-bottom-navigation')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('mobile-a4-preview-button')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('writer-panel-preview')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reader-context-bar')), findsNothing);
    expect(find.byKey(const ValueKey('reader-left-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-right-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('reader-navigation')), findsNothing);
    expect(find.byKey(const ValueKey('reader-settings-button')), findsNothing);
  });
}
