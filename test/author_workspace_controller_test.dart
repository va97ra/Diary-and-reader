import 'dart:async';

import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/workspace_save_state.dart';
import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_author_workspace_repository.dart';

void main() {
  test('creates a book and persists chapter and scene hierarchy', () async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');

    final chapter = controller.activeSection!;
    controller.addSection(BookSectionType.scene);
    final scene = controller.activeSection!;
    await controller.flush();

    expect(controller.activeProject!.metadata.title, 'Новая книга');
    expect(scene.parentId, chapter.id);
    expect(repository.snapshot!.activeProject!.sections, hasLength(2));
  });

  test('persists the selected page orientation with the book', () async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');

    controller.updateLayoutSettings(
      controller.activeProject!.layoutSettings.copyWith(
        orientation: BookPageOrientation.landscape,
      ),
    );
    await controller.flush();

    expect(
      repository.snapshot!.activeProject!.layoutSettings.orientation,
      BookPageOrientation.landscape,
    );
  });

  test('persists a section word target and reports save state', () async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');

    controller.updateSectionTargetWords(2500);

    expect(controller.activeSection!.targetWords, 2500);
    expect(controller.saveState, WorkspaceSaveState.saving);

    await controller.flush();

    expect(
      repository.snapshot!.activeProject!.activeSection!.targetWords,
      2500,
    );
    expect(controller.saveState, WorkspaceSaveState.saved);
  });

  test('persists project paragraph settings', () async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');

    controller.updateParagraphSettings(
      BookParagraphSettings.forPreset(BookParagraphPreset.classic),
    );
    await controller.flush();

    final saved = repository.snapshot!.activeProject!.paragraphSettings;
    expect(saved.preset, BookParagraphPreset.classic);
    expect(saved.paragraphIndentMm, 5);
  });

  test('serializes saves so an older write cannot win a race', () async {
    final repository = _ControlledAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');
    repository.holdWrites = true;

    controller.updateSectionTitle('Первая версия');
    final firstSave = controller.flush();
    await Future<void>.delayed(Duration.zero);
    controller.updateSectionTitle('Последняя версия');
    final secondSave = controller.flush();
    await Future<void>.delayed(Duration.zero);

    expect(repository.pendingWrites, hasLength(1));
    repository.completeNextWrite();
    await Future<void>.delayed(Duration.zero);
    expect(repository.pendingWrites, hasLength(1));
    repository.completeNextWrite();
    await Future.wait([firstSave, secondSave]);

    expect(
      repository.snapshot!.activeProject!.activeSection!.title,
      'Последняя версия',
    );
    expect(controller.saveState, WorkspaceSaveState.saved);
  });
}

class _ControlledAuthorWorkspaceRepository
    implements AuthorWorkspaceRepository {
  AuthorWorkspaceSnapshot? snapshot;
  bool holdWrites = false;
  final pendingWrites = <Completer<void>>[];

  @override
  Future<AuthorWorkspaceSnapshot?> load() async => snapshot;

  @override
  Future<void> save(AuthorWorkspaceSnapshot nextSnapshot) async {
    if (holdWrites) {
      final completer = Completer<void>();
      pendingWrites.add(completer);
      await completer.future;
    }
    snapshot = AuthorWorkspaceSnapshot.fromJson(nextSnapshot.toJson());
  }

  void completeNextWrite() => pendingWrites.removeAt(0).complete();
}
