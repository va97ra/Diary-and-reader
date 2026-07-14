import 'dart:convert';

import 'package:dnevnik/features/books/application/legacy_diary_migrator.dart';
import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';
import 'package:dnevnik/features/diary/domain/diary_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesAuthorWorkspaceRepository
    implements AuthorWorkspaceRepository {
  const PreferencesAuthorWorkspaceRepository(this._preferences);

  static const storageKey = 'author.workspace.v2';
  static const backupKey = 'author.workspace.v2.backup';
  static const legacyStorageKey = 'diary.storage.v1';
  static const legacyBackupKey = 'diary.storage.v1.backup';

  final SharedPreferences _preferences;

  @override
  Future<AuthorWorkspaceSnapshot?> load() async {
    final current =
        _decodeWorkspace(_preferences.getString(storageKey)) ??
        _decodeWorkspace(_preferences.getString(backupKey));
    if (current != null) return current;

    final legacy =
        _decodeDiary(_preferences.getString(legacyStorageKey)) ??
        _decodeDiary(_preferences.getString(legacyBackupKey));
    if (legacy == null) return null;

    final migrated = LegacyDiaryMigrator.migrate(legacy);
    await save(migrated);
    return migrated;
  }

  @override
  Future<void> save(AuthorWorkspaceSnapshot snapshot) async {
    final encoded = jsonEncode(snapshot.toJson());
    final previous = _preferences.getString(storageKey);
    if (previous != null && previous != encoded) {
      await _preferences.setString(backupKey, previous);
    }
    await _preferences.setString(storageKey, encoded);
  }

  AuthorWorkspaceSnapshot? _decodeWorkspace(String? encoded) {
    final json = _decodeMap(encoded);
    if (json == null || json['formatVersion'] != 2) return null;
    return AuthorWorkspaceSnapshot.fromJson(json);
  }

  DiarySnapshot? _decodeDiary(String? encoded) {
    final json = _decodeMap(encoded);
    return json == null ? null : DiarySnapshot.fromJson(json);
  }

  Map<String, dynamic>? _decodeMap(String? encoded) {
    if (encoded == null) return null;
    try {
      final decoded = jsonDecode(encoded);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }
}
