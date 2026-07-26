import 'dart:io';

import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_import_coordinator.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_reading_session_loader.dart';
import 'package:dnevnik/features/books/data/file_book_source_storage.dart';
import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_author_workspace_repository.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('literia-books-');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('imports a private source copy and skips a content duplicate', () async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(seedManuscript: false),
    );
    await controller.load(preferredLanguage: 'ru');
    final storage = FileBookSourceStorage(supportDirectory: directory);
    final coordinator = BookImportCoordinator(
      controller: controller,
      sourceStorage: storage,
    );
    final file = BookImportFile(
      name: 'sample.fb2',
      bytes: await File('test/fixtures/import_sample.fb2').readAsBytes(),
      sourceUri: 'content://books/sample',
    );

    final first = await coordinator.import([file], availableBytes: 10000000);
    final second = await coordinator.import([file], availableBytes: 10000000);

    expect(first.imported, hasLength(1));
    expect(second.imported, isEmpty);
    expect(second.duplicateCount, 1);
    final project = first.imported.single;
    expect(project.isCatalogOnly, isTrue);
    expect(project.sourceFingerprint, isNotEmpty);
    expect(project.sourceExternalUri, 'content://books/sample');
    expect(project.sourceFileSize, file.bytes.length);
    final stored = File(
      '${directory.path}${Platform.pathSeparator}'
      '${project.sourceStoredPath.replaceAll('/', Platform.pathSeparator)}',
    );
    expect(await stored.readAsBytes(), file.bytes);
  });

  test('deleting only the original keeps processed book data', () async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(seedManuscript: false),
    );
    await controller.load(preferredLanguage: 'ru');
    final storage = FileBookSourceStorage(supportDirectory: directory);
    final file = BookImportFile(
      name: 'sample.fb2',
      bytes: await File('test/fixtures/import_sample.fb2').readAsBytes(),
    );
    final result = await BookImportCoordinator(
      controller: controller,
      sourceStorage: storage,
    ).import([file]);
    final project = result.imported.single;
    final loaded = await BookReadingSessionLoader(storage).load(project);
    expect(loaded.sections, isNotEmpty);
    controller.selectProject(project.id);
    controller.beginReaderSession(hydratedProject: loaded);
    controller.finishReaderSession();

    controller.clearImportedBookStoredSource(project.id);
    await controller.flush();
    await storage.deleteOriginal(project);

    final retained = controller.projects.single;
    expect(retained.isCatalogOnly, isTrue);
    expect(retained.assets, isNotEmpty);
    expect(retained.sourceStoredPath, isEmpty);
    expect(retained.sourceFingerprint, isNotEmpty);
    final overview = await storage.inspect(controller.projects);
    expect(overview.originalBytes, 0);
    expect(overview.processedBytes, greaterThan(0));
    expect(await storage.loadProcessed(retained), isNotNull);
  });

  test('rolls back the import when the workspace cannot be saved', () async {
    final controller = AuthorWorkspaceController(_FailingSaveRepository());
    await controller.load(preferredLanguage: 'ru');
    final storage = FileBookSourceStorage(supportDirectory: directory);
    final file = BookImportFile(
      name: 'sample.fb2',
      bytes: File('test/fixtures/import_sample.fb2').readAsBytesSync(),
    );

    final result = await BookImportCoordinator(
      controller: controller,
      sourceStorage: storage,
    ).import([file]);

    expect(result.imported, isEmpty);
    expect(result.items.single.failure, BookImportItemFailure.storage);
    expect(controller.projects, isEmpty);
    final retainedFiles = await directory
        .list(recursive: true)
        .where((entity) => entity is File)
        .toList();
    expect(retainedFiles, isEmpty);
    controller.dispose();
  });

  test('cleanup removes orphaned and temporary source directories', () async {
    final storage = FileBookSourceStorage(supportDirectory: directory);
    final orphan = Directory(
      '${directory.path}${Platform.pathSeparator}library'
      '${Platform.pathSeparator}orphan',
    );
    final temporary = Directory(
      '${directory.path}${Platform.pathSeparator}library'
      '${Platform.pathSeparator}.tmp',
    );
    await orphan.create(recursive: true);
    await temporary.create(recursive: true);
    await File(
      '${orphan.path}${Platform.pathSeparator}source.fb2',
    ).writeAsString('orphan');
    await File(
      '${temporary.path}${Platform.pathSeparator}copy.pending',
    ).writeAsString('pending');

    await storage.cleanup(const []);

    expect(await orphan.exists(), isFalse);
    expect(await temporary.exists(), isFalse);
  });
}

class _FailingSaveRepository implements AuthorWorkspaceRepository {
  @override
  Future<AuthorWorkspaceSnapshot?> load() async => null;

  @override
  Future<void> save(AuthorWorkspaceSnapshot snapshot) =>
      Future<void>.error(Exception('Storage unavailable'));
}
