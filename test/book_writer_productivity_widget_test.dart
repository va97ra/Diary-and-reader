import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/literia_test_navigation.dart';
import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('opens writing statistics and saves daily and project goals', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await tester.tap(find.byKey(const ValueKey('writer-more-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Статистика писателя'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('writing-statistics-sheet')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('daily-writing-goal')),
      '750',
    );
    await tester.enterText(
      find.byKey(const ValueKey('project-writing-goal')),
      '90000',
    );
    await tester.drag(
      find.byKey(const ValueKey('writing-statistics-sheet')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-writing-goals')));
    await tester.pump();

    expect(controller.activeProject!.writingState.dailyTargetWords, 750);
    expect(controller.activeProject!.writingState.projectTargetWords, 90000);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('shows deleted chapter in the section trash', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.addSection(BookSectionType.chapter);
    final deletedTitle = controller.activeSection!.title;
    await controller.deleteSectionSafely(
      controller.activeSection!.id,
      safetyLabel: 'Перед удалением',
    );
    final trashId = controller.activeProject!.sectionTrash.single.id;

    await tester.binding.setSurfaceSize(const Size(800, 1000));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    await tester.tap(find.byKey(const ValueKey('writer-more-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Корзина разделов'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('section-trash-sheet')), findsOneWidget);
    expect(find.byKey(ValueKey('trash-entry-$trashId')), findsOneWidget);
    expect(find.text(deletedTitle), findsWidgets);
    expect(find.textContaining('Разделов: 1'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
