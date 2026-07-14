import 'package:dnevnik/features/diary/data/preferences_diary_repository.dart';
import 'package:dnevnik/features/diary/domain/diary_entry.dart';
import 'package:dnevnik/features/diary/domain/diary_snapshot.dart';
import 'package:dnevnik/features/diary/domain/page_margins.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads the previous backup when primary storage is corrupted', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesDiaryRepository(preferences);
    final first = _snapshot('First');
    final second = _snapshot('Second');

    await repository.save(first);
    await repository.save(second);
    await preferences.setString('diary.storage.v1', '{broken json');

    final restored = await repository.load();
    expect(restored!.entries.single.title, 'First');
  });
}

DiarySnapshot _snapshot(String title) {
  final entry = DiaryEntry.create(title: title);
  return DiarySnapshot(
    entries: [entry],
    activeEntryId: entry.id,
    languageCode: 'ru',
    margins: const PageMargins.normal(),
  );
}
