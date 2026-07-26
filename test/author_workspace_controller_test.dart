import 'dart:async';

import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/workspace_save_state.dart';
import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
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

  test('saves during uninterrupted typing before the idle delay', () async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(
      repository,
      saveDebounce: const Duration(milliseconds: 90),
      maxSaveDelay: const Duration(milliseconds: 30),
    );
    await controller.load(preferredLanguage: 'ru');

    for (var index = 0; index < 5; index++) {
      controller.updateSectionContent([
        {'insert': 'Непрерывный набор $index\n'},
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(repository.saveCount, greaterThanOrEqualTo(1));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(
      richDocumentPlainText(
        repository.snapshot!.activeProject!.activeSection!.content,
      ),
      'Непрерывный набор 4\n',
    );
    expect(controller.saveState, WorkspaceSaveState.saved);
    controller.dispose();
  });

  test('reports a save error and succeeds when retried', () async {
    final repository = _RecoveringAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent(const [
      {'insert': 'Текст для повторного сохранения\n'},
    ]);

    expect(await controller.flushWithResult(), isFalse);
    expect(controller.saveState, WorkspaceSaveState.error);

    repository.failWrites = false;
    expect(await controller.flushWithResult(), isTrue);
    expect(controller.saveState, WorkspaceSaveState.saved);
    expect(
      richDocumentPlainText(
        repository.snapshot!.activeProject!.activeSection!.content,
      ),
      'Текст для повторного сохранения\n',
    );
    controller.dispose();
  });

  test('replaces text across the manuscript and persists the result', () async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent([
      {'insert': 'Первый герой. Герой вернулся.\n'},
    ]);
    controller.addSection(BookSectionType.chapter);
    controller.updateSectionContent([
      {'insert': 'Ещё один герой.\n'},
    ]);

    final count = controller.replaceAllInManuscript('герой', 'персонаж');
    await controller.flush();

    expect(count, 3);
    expect(
      repository.snapshot!.activeProject!.sections
          .map((section) => section.content)
          .map(richDocumentPlainText)
          .join(),
      isNot(contains('герой')),
    );
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

  test('removes reader locations that belong to a deleted section', () async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    final firstSectionId = controller.activeSection!.id;
    controller.addSection(BookSectionType.chapter);
    final deletedSectionId = controller.activeSection!.id;
    controller.updateReaderProgress(
      BookReaderProgress(sectionId: deletedSectionId, sectionProgress: 0.5),
    );
    controller.updateReaderAnnotations(
      BookReaderAnnotations(
        bookmarks: [
          BookReaderBookmark.create(
            sectionId: deletedSectionId,
            sectionProgress: 0.5,
            excerpt: 'Удаляемая глава',
          ),
        ],
      ),
    );

    controller.deleteSection(deletedSectionId);

    expect(controller.activeProject!.readerProgress.sectionId, firstSectionId);
    expect(controller.activeProject!.readerAnnotations.bookmarks, isEmpty);
  });

  test('serializes saves so an older write cannot win a race', () async {
    final repository = _ControlledAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');
    controller.addProject();
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

  test('restores a version and first saves the replaced state', () async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');
    controller.updateMetadata(
      controller.activeProject!.metadata.copyWith(title: 'Первая редакция'),
    );
    final version = await controller.createVersion(label: 'Стабильная');
    controller.updateMetadata(
      controller.activeProject!.metadata.copyWith(title: 'Новые правки'),
    );

    await controller.restoreVersion(
      version!,
      safetyLabel: 'Перед восстановлением',
    );

    expect(controller.activeProject!.metadata.title, 'Первая редакция');
    final versions = await controller.listVersions();
    expect(versions, hasLength(2));
    expect(versions.first.label, 'Перед восстановлением');
    expect(versions.first.project.metadata.title, 'Новые правки');
    expect(
      repository.snapshot!.activeProject!.metadata.title,
      'Первая редакция',
    );
  });

  test('creates an automatic checkpoint before deleting a section', () async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');
    controller.addSection(BookSectionType.chapter);
    final deletedId = controller.activeSection!.id;

    await controller.deleteSectionSafely(
      deletedId,
      safetyLabel: 'Перед удалением',
    );

    expect(controller.activeProject!.sectionTrash, hasLength(1));
    expect((await controller.listVersions()).single.label, 'Перед удалением');
  });

  test('imports a backup under the current project identity', () async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    final originalId = controller.activeProject!.id;
    final imported = controller.activeProject!.copyWith(
      metadata: const BookMetadata(title: 'Книга из файла'),
    );

    await controller.importProject(imported, safetyLabel: 'Перед импортом');

    expect(controller.activeProject!.id, originalId);
    expect(controller.activeProject!.metadata.title, 'Книга из файла');
    expect((await controller.listVersions()).single.label, 'Перед импортом');
  });

  test('persists imported books but blocks authoring changes', () async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');
    final timestamp = DateTime.utc(2026, 7, 15);
    final section = BookSection(
      id: 'import-section',
      title: 'Импортированная глава',
      type: BookSectionType.chapter,
      status: DraftStatus.complete,
      content: const [
        {'insert': 'Исходный текст\n'},
      ],
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    final imported = BookProject(
      id: 'imported-book',
      metadata: const BookMetadata(title: 'Чужая книга'),
      sections: [section],
      activeSectionId: section.id,
      createdAt: timestamp,
      updatedAt: timestamp,
      readerProgress: BookReaderProgress(sectionId: section.id),
      kind: BookProjectKind.importedBook,
      sourceFormat: 'EPUB',
      sourceFileName: 'book.epub',
    );

    controller.addImportedBook(imported);
    controller.updateSectionTitle('Случайная правка');
    controller.updateSectionContent(const [
      {'insert': 'Изменённый текст\n'},
    ]);
    controller.updateReaderProgress(
      BookReaderProgress(sectionId: section.id, sectionProgress: 0.5),
    );
    await controller.flush();

    expect(controller.activeSection!.title, 'Импортированная глава');
    expect(controller.activeSection!.content, section.content);
    expect(controller.activeProject!.readerProgress.sectionProgress, 0.5);
    expect(
      repository.snapshot!.activeProject!.kind,
      BookProjectKind.importedBook,
    );
    expect(repository.snapshot!.activeProject!.sourceFileName, 'book.epub');
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

class _RecoveringAuthorWorkspaceRepository
    implements AuthorWorkspaceRepository {
  _RecoveringAuthorWorkspaceRepository()
    : snapshot = MemoryAuthorWorkspaceRepository().snapshot;

  AuthorWorkspaceSnapshot? snapshot;
  bool failWrites = true;

  @override
  Future<AuthorWorkspaceSnapshot?> load() async => snapshot;

  @override
  Future<void> save(AuthorWorkspaceSnapshot nextSnapshot) async {
    if (failWrites) throw Exception('Storage unavailable');
    snapshot = AuthorWorkspaceSnapshot.fromJson(nextSnapshot.toJson());
  }
}
