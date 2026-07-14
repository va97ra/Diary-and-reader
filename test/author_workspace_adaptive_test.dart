import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('shows manuscript and properties on desktop', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Рукопись'), findsOneWidget);
    expect(find.text('Свойства'), findsOneWidget);
    expect(find.byKey(const ValueKey('book-page-1')), findsOneWidget);
    expect(find.textContaining('A4 297×210 мм'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('shows compact bottom navigation on mobile', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Редактор'), findsOneWidget);
    expect(find.text('Лист A4 1 из 1'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
}
