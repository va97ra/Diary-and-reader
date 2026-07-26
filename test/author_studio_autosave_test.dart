import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('flushes pending text when the app leaves the foreground', (
    tester,
  ) async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(
      repository,
      saveDebounce: const Duration(hours: 1),
      maxSaveDelay: const Duration(hours: 1),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent(const [
      {'insert': 'Текст перед сворачиванием\n'},
    ]);
    await tester.pumpWidget(AuthorStudioApp(controller: controller));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();

    expect(
      richDocumentPlainText(
        repository.snapshot!.activeProject!.activeSection!.content,
      ),
      'Текст перед сворачиванием\n',
    );

    controller.updateSectionContent(const [
      {'insert': 'Текст перед фоновым режимом\n'},
    ]);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(
      richDocumentPlainText(
        repository.snapshot!.activeProject!.activeSection!.content,
      ),
      'Текст перед фоновым режимом\n',
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    controller.dispose();
  });
}
