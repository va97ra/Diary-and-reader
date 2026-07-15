import 'dart:io';

import 'package:dnevnik/features/books/data/file_book_version_repository.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('dnevnik-versions-');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('persists, orders and deletes named project versions', () async {
    final repository = FileBookVersionRepository(directory: directory);
    final project = BookProject.create(
      title: 'Версия 1',
      chapterTitle: 'Глава',
      now: DateTime(2026),
    );
    final first = await repository.create(
      project: project,
      label: 'До редактуры',
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));
    final second = await repository.create(
      project: project.copyWith(
        metadata: project.metadata.copyWith(title: 'Версия 2'),
      ),
      label: 'После редактуры',
    );

    final reloaded = FileBookVersionRepository(directory: directory);
    final versions = await reloaded.list(project.id);
    expect(versions.map((version) => version.id), [second.id, first.id]);
    expect(versions.first.project.metadata.title, 'Версия 2');
    expect(versions.last.label, 'До редактуры');

    await reloaded.delete(projectId: project.id, versionId: second.id);
    expect(await reloaded.list(project.id), hasLength(1));
  });

  test('skips a corrupt version without hiding valid snapshots', () async {
    final repository = FileBookVersionRepository(directory: directory);
    final project = BookProject.create(
      title: 'Книга',
      chapterTitle: 'Глава',
      now: DateTime(2026),
    );
    await repository.create(project: project);
    final projectDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}${project.id}',
    );
    await File(
      '${projectDirectory.path}${Platform.pathSeparator}corrupt.json',
    ).writeAsString('{повреждено');

    final versions = await repository.list(project.id);

    expect(versions, hasLength(1));
    expect(versions.single.project.metadata.title, 'Книга');
  });
}
