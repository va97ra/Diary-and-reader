import 'dart:convert';

import 'package:dnevnik/features/books/data/preferences_author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/legacy/legacy_diary_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('migrates legacy diary storage once and persists version 2', () async {
    final entry = LegacyDiaryEntry(
      id: 'legacy-entry',
      title: 'Пролог',
      createdAt: DateTime.utc(2026),
      pages: const [
        [
          {'insert': '\n'},
        ],
      ],
    );
    final legacy = LegacyDiarySnapshot(
      entries: [entry],
      activeEntryId: entry.id,
      languageCode: 'ru',
    );
    SharedPreferences.setMockInitialValues({
      PreferencesAuthorWorkspaceRepository.legacyStorageKey: jsonEncode(
        legacy.toJson(),
      ),
    });
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesAuthorWorkspaceRepository(preferences);

    final migrated = await repository.load();

    expect(migrated!.activeProject!.sections.single.title, 'Пролог');
    expect(
      preferences.getString(PreferencesAuthorWorkspaceRepository.storageKey),
      isNotNull,
    );
  });

  test('uses version 2 backup when primary storage is corrupted', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesAuthorWorkspaceRepository(preferences);
    final first = _workspace('Первая книга');
    final second = _workspace('Вторая книга');

    await repository.save(first);
    await repository.save(second);
    await preferences.setString(
      PreferencesAuthorWorkspaceRepository.storageKey,
      '{broken json',
    );

    final restored = await repository.load();
    expect(restored!.activeProject!.metadata.title, 'Первая книга');
  });
}

AuthorWorkspaceSnapshot _workspace(String title) {
  final project = BookProject.create(title: title, chapterTitle: 'Глава 1');
  return AuthorWorkspaceSnapshot(
    projects: [project],
    activeProjectId: project.id,
    languageCode: 'ru',
  );
}
