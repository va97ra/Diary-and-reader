import 'dart:io';

import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_import_parser.dart';
import 'package:dnevnik/features/books/application/legacy_diary_migrator.dart';
import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/legacy/legacy_diary_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('autosave survives an app lifecycle restart', (tester) async {
    final repository = _MemoryWorkspaceRepository();
    final firstController = AuthorWorkspaceController(
      repository,
      saveDebounce: const Duration(hours: 1),
      maxSaveDelay: const Duration(hours: 1),
    );
    await firstController.load(preferredLanguage: 'ru');
    firstController.updateSectionContent(const [
      {'insert': 'Ни одной потерянной буквы\n'},
    ]);
    await tester.pumpWidget(AuthorStudioApp(controller: firstController));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    firstController.dispose();

    final restoredController = AuthorWorkspaceController(repository);
    await restoredController.load(preferredLanguage: 'ru');
    expect(
      richDocumentPlainText(restoredController.activeSection!.content),
      'Ни одной потерянной буквы\n',
    );
    restoredController.dispose();
  });

  test(
    'legacy diary data remains readable after migration and reload',
    () async {
      final migrated = LegacyDiaryMigrator.migrate(
        LegacyDiarySnapshot(
          entries: [
            LegacyDiaryEntry(
              id: 'legacy-entry',
              title: 'Старая глава',
              createdAt: DateTime.utc(2025),
              pages: const [
                [
                  {'insert': 'Сохранённый старый текст\n'},
                ],
              ],
            ),
          ],
          activeEntryId: 'legacy-entry',
          languageCode: 'ru',
        ),
      );
      final repository = _MemoryWorkspaceRepository(seed: migrated);
      final controller = AuthorWorkspaceController(repository);
      await controller.load(preferredLanguage: 'ru');

      expect(controller.activeSection!.title, 'Старая глава');
      expect(
        richDocumentPlainText(controller.activeSection!.content),
        'Сохранённый старый текст\n',
      );
      controller.dispose();
    },
  );

  test('FB2 import is persisted and remains readable', () async {
    final bytes = await File('test/fixtures/import_sample.fb2').readAsBytes();
    final imported = BookImportParser.parse(
      BookImportFile(name: 'import_sample.fb2', bytes: bytes),
    );
    final repository = _MemoryWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');
    controller.addImportedBook(imported);
    await controller.flush();
    controller.dispose();

    final restoredController = AuthorWorkspaceController(repository);
    await restoredController.load(preferredLanguage: 'ru');
    final restored = restoredController.projects.single;
    expect(restored.isReadOnly, isTrue);
    expect(restored.sections, isNotEmpty);
    expect(
      restored.sections.any(
        (section) => richDocumentPlainText(section.content).trim().isNotEmpty,
      ),
      isTrue,
    );
    restoredController.dispose();
  });
}

class _MemoryWorkspaceRepository implements AuthorWorkspaceRepository {
  _MemoryWorkspaceRepository({AuthorWorkspaceSnapshot? seed}) : snapshot = seed;

  AuthorWorkspaceSnapshot? snapshot;

  @override
  Future<AuthorWorkspaceSnapshot?> load() async => snapshot;

  @override
  Future<void> save(AuthorWorkspaceSnapshot snapshot) async {
    this.snapshot = AuthorWorkspaceSnapshot.fromJson(snapshot.toJson());
  }
}
