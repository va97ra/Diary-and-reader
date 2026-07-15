import 'dart:convert';

import 'package:dnevnik/features/books/data/preferences_book_version_repository.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('keeps the newest five Web versions per project', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesBookVersionRepository(preferences);
    final project = BookProject.create(
      title: 'Версия 0',
      chapterTitle: 'Глава',
      now: DateTime(2026),
    );

    for (var index = 0; index < 6; index++) {
      await repository.create(
        project: project.copyWith(
          metadata: project.metadata.copyWith(title: 'Версия $index'),
        ),
        label: 'Снимок $index',
      );
    }

    final restored = await PreferencesBookVersionRepository(
      preferences,
    ).list(project.id);
    expect(restored, hasLength(5));
    expect(restored.first.label, 'Снимок 5');
    expect(restored.last.label, 'Снимок 1');
  });

  test('keeps valid Web snapshots when one entry is corrupt', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesBookVersionRepository(preferences);
    final project = BookProject.create(
      title: 'Книга',
      chapterTitle: 'Глава',
      now: DateTime(2026),
    );
    await repository.create(project: project, label: 'Исправный снимок');
    final decoded =
        jsonDecode(
              preferences.getString(
                PreferencesBookVersionRepository.storageKey,
              )!,
            )
            as List<dynamic>;
    decoded.add({'id': 'broken'});
    await preferences.setString(
      PreferencesBookVersionRepository.storageKey,
      jsonEncode(decoded),
    );

    final versions = await repository.list(project.id);

    expect(versions.single.label, 'Исправный снимок');
  });
}
