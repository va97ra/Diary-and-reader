import 'dart:convert';

import 'package:dnevnik/features/diary/domain/diary_repository.dart';
import 'package:dnevnik/features/diary/domain/diary_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesDiaryRepository implements DiaryRepository {
  const PreferencesDiaryRepository(this._preferences);

  static const _storageKey = 'diary.storage.v1';
  static const _backupKey = 'diary.storage.v1.backup';
  final SharedPreferences _preferences;

  @override
  Future<DiarySnapshot?> load() async {
    return _decode(_preferences.getString(_storageKey)) ??
        _decode(_preferences.getString(_backupKey));
  }

  @override
  Future<void> save(DiarySnapshot snapshot) async {
    final encoded = jsonEncode(snapshot.toJson());
    final previous = _preferences.getString(_storageKey);
    if (previous != null && previous != encoded) {
      await _preferences.setString(_backupKey, previous);
    }
    await _preferences.setString(_storageKey, encoded);
  }

  DiarySnapshot? _decode(String? encoded) {
    if (encoded == null) return null;
    try {
      final json = jsonDecode(encoded);
      return json is Map
          ? DiarySnapshot.fromJson(Map<String, dynamic>.from(json))
          : null;
    } on FormatException {
      return null;
    }
  }
}
