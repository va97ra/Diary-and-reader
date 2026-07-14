import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('flows an overflowing chapter onto another A4 page', (
    tester,
  ) async {
    final now = DateTime(2026);
    final section = BookSection(
      id: 'chapter-1',
      title: 'Глава 1',
      type: BookSectionType.chapter,
      status: DraftStatus.draft,
      content: [
        {'insert': '${'Длинный текст рукописи. ' * 500}\n'},
      ],
      createdAt: now,
      updatedAt: now,
    );
    final project = BookProject(
      id: 'book-1',
      metadata: const BookMetadata(title: 'Книга'),
      sections: [section],
      activeSectionId: section.id,
      createdAt: now,
      updatedAt: now,
    );
    final repository = MemoryAuthorWorkspaceRepository()
      ..snapshot = AuthorWorkspaceSnapshot(
        projects: [project],
        activeProjectId: project.id,
        languageCode: 'ru',
      );
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    for (var index = 0; index < 20; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byKey(const ValueKey('book-page-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('book-page-2')), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
}
