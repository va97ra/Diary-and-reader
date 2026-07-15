import 'dart:convert';
import 'dart:io';

import 'package:dnevnik/features/books/data/file_author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_author_workspace_repository.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dnevnik-workspace-');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('stores the workspace in a versioned durable envelope', () async {
    final repository = FileAuthorWorkspaceRepository(directory: directory);

    await repository.save(_snapshot('Первая книга'));

    final primary = _file(
      directory,
      FileAuthorWorkspaceRepository.primaryFileName,
    );
    final envelope = Map<String, dynamic>.from(
      jsonDecode(await primary.readAsString()) as Map,
    );
    expect(
      envelope['storageFormatVersion'],
      FileAuthorWorkspaceRepository.storageFormatVersion,
    );
    expect(envelope['savedAt'], isNotEmpty);
    expect(
      (envelope['workspace'] as Map)['formatVersion'],
      AuthorWorkspaceSnapshot.formatVersion,
    );

    final restored = await FileAuthorWorkspaceRepository(
      directory: directory,
    ).load();
    expect(restored?.activeProject?.metadata.title, 'Первая книга');
  });

  test('recovers through two rotating backups', () async {
    final repository = FileAuthorWorkspaceRepository(
      directory: directory,
      backupInterval: Duration.zero,
    );
    await repository.save(_snapshot('Версия 1'));
    await repository.save(_snapshot('Версия 2'));
    await repository.save(_snapshot('Версия 3'));

    final primary = _file(
      directory,
      FileAuthorWorkspaceRepository.primaryFileName,
    );
    await primary.writeAsString('{повреждено');
    final firstRecovery = await FileAuthorWorkspaceRepository(
      directory: directory,
    ).load();
    expect(firstRecovery?.activeProject?.metadata.title, 'Версия 2');

    final firstBackup = _file(
      directory,
      FileAuthorWorkspaceRepository.firstBackupFileName,
    );
    await firstBackup.writeAsString('{тоже повреждено');
    final secondRecovery = await FileAuthorWorkspaceRepository(
      directory: directory,
    ).load();
    expect(secondRecovery?.activeProject?.metadata.title, 'Версия 1');
  });

  test('uses rollback after an interrupted atomic replacement', () async {
    final repository = FileAuthorWorkspaceRepository(directory: directory);
    await repository.save(_snapshot('Последняя сохранённая версия'));
    final primary = _file(
      directory,
      FileAuthorWorkspaceRepository.primaryFileName,
    );
    final rollback = _file(
      directory,
      FileAuthorWorkspaceRepository.rollbackFileName,
    );
    await primary.rename(rollback.path);
    await _file(
      directory,
      FileAuthorWorkspaceRepository.pendingFileName,
    ).writeAsString('{незавершённая запись');

    final restored = await FileAuthorWorkspaceRepository(
      directory: directory,
    ).load();

    expect(
      restored?.activeProject?.metadata.title,
      'Последняя сохранённая версия',
    );
  });

  test('migrates preferences once and then prefers the native file', () async {
    final legacyRepository = MemoryAuthorWorkspaceRepository()
      ..snapshot = _snapshot('Старая книга');
    final repository = FileAuthorWorkspaceRepository(
      directory: directory,
      migrationRepository: legacyRepository,
    );

    final migrated = await repository.load();
    expect(migrated?.activeProject?.metadata.title, 'Старая книга');
    expect(
      await _file(
        directory,
        FileAuthorWorkspaceRepository.primaryFileName,
      ).exists(),
      isTrue,
    );

    legacyRepository.snapshot = _snapshot('Не должна загрузиться');
    final reloaded = await FileAuthorWorkspaceRepository(
      directory: directory,
      migrationRepository: legacyRepository,
    ).load();
    expect(reloaded?.activeProject?.metadata.title, 'Старая книга');
  });
}

AuthorWorkspaceSnapshot _snapshot(String title) {
  final project = BookProject.create(
    title: title,
    chapterTitle: 'Глава 1',
    languageCode: 'ru',
  );
  return AuthorWorkspaceSnapshot(
    projects: [project],
    activeProjectId: project.id,
    languageCode: 'ru',
  );
}

File _file(Directory directory, String name) =>
    File('${directory.path}${Platform.pathSeparator}$name');
