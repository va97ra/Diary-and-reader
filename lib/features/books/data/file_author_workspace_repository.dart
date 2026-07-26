import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';

class FileAuthorWorkspaceRepository implements AuthorWorkspaceRepository {
  FileAuthorWorkspaceRepository({
    required this.directory,
    this.migrationRepository,
    this.backupInterval = const Duration(minutes: 5),
  });

  static const primaryFileName = 'author-workspace-v2.json';
  static const pendingFileName = 'author-workspace-v2.pending';
  static const rollbackFileName = 'author-workspace-v2.rollback';
  static const firstBackupFileName = 'author-workspace-v2.backup-1.json';
  static const secondBackupFileName = 'author-workspace-v2.backup-2.json';
  static const storageFormatVersion = 1;

  final Directory directory;
  final AuthorWorkspaceRepository? migrationRepository;
  final Duration backupInterval;

  bool? _primaryKnownValid;

  File get _primary => _file(primaryFileName);
  File get _pending => _file(pendingFileName);
  File get _rollback => _file(rollbackFileName);
  File get _firstBackup => _file(firstBackupFileName);
  File get _secondBackup => _file(secondBackupFileName);

  @override
  Future<AuthorWorkspaceSnapshot?> load() async {
    await directory.create(recursive: true);
    final candidates = <File>[
      _primary,
      _rollback,
      _pending,
      _firstBackup,
      _secondBackup,
    ];
    for (var index = 0; index < candidates.length; index++) {
      final snapshot = await _readSnapshot(candidates[index]);
      if (snapshot == null) continue;
      _primaryKnownValid = index == 0;
      return snapshot;
    }

    _primaryKnownValid = false;
    final migrated = await migrationRepository?.load();
    if (migrated == null) return null;
    await save(migrated);
    return migrated;
  }

  @override
  Future<void> save(AuthorWorkspaceSnapshot snapshot) async {
    await directory.create(recursive: true);
    await _writePending(snapshot);

    final primaryExists = await _primary.exists();
    final preservePrimary = primaryExists && (_primaryKnownValid ?? true);
    if (preservePrimary) {
      await _deleteIfExists(_rollback);
      await _primary.rename(_rollback.path);
    } else if (primaryExists) {
      await _primary.delete();
    }

    try {
      await _pending.rename(_primary.path);
      _primaryKnownValid = true;
    } on FileSystemException {
      if (!await _primary.exists() && await _rollback.exists()) {
        await _rollback.rename(_primary.path);
        _primaryKnownValid = true;
      }
      rethrow;
    }

    await _archiveRollback();
  }

  Future<void> _writePending(AuthorWorkspaceSnapshot snapshot) async {
    await _deleteIfExists(_pending);
    final savedAt = DateTime.now().toUtc().toIso8601String();
    final encoded = await Isolate.run(() => _encodeSnapshot(snapshot, savedAt));
    await _pending.writeAsString(encoded, encoding: utf8, flush: true);
  }

  Future<void> _archiveRollback() async {
    if (!await _rollback.exists()) return;
    try {
      if (!await _backupIsDue()) {
        await _rollback.delete();
        return;
      }
      await _deleteIfExists(_secondBackup);
      if (await _firstBackup.exists()) {
        await _firstBackup.rename(_secondBackup.path);
      }
      await _rollback.rename(_firstBackup.path);
    } on FileSystemException {
      // The new primary file is already durable. Keep any surviving rollback
      // or backup file so the next launch can still recover from it.
    }
  }

  Future<bool> _backupIsDue() async {
    if (!await _firstBackup.exists()) return true;
    if (backupInterval <= Duration.zero) return true;
    final modified = (await _firstBackup.stat()).modified;
    return DateTime.now().difference(modified) >= backupInterval;
  }

  Future<AuthorWorkspaceSnapshot?> _readSnapshot(File file) async {
    if (!await file.exists()) return null;
    try {
      final encoded = await file.readAsString(encoding: utf8);
      return await Isolate.run(() => _decodeSnapshot(encoded));
    } on FileSystemException {
      rethrow;
    } on Object {
      return null;
    }
  }

  File _file(String name) =>
      File('${directory.path}${Platform.pathSeparator}$name');

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) await file.delete();
  }
}

String _encodeSnapshot(AuthorWorkspaceSnapshot snapshot, String savedAt) =>
    jsonEncode({
      'storageFormatVersion':
          FileAuthorWorkspaceRepository.storageFormatVersion,
      'savedAt': savedAt,
      'workspace': snapshot.toJson(),
    });

AuthorWorkspaceSnapshot? _decodeSnapshot(String encoded) {
  final decoded = jsonDecode(encoded);
  if (decoded is! Map) return null;
  final envelope = Map<String, dynamic>.from(decoded);
  if (envelope['storageFormatVersion'] !=
      FileAuthorWorkspaceRepository.storageFormatVersion) {
    return null;
  }
  final workspace = envelope['workspace'];
  if (workspace is! Map) return null;
  final json = Map<String, dynamic>.from(workspace);
  if (json['formatVersion'] != AuthorWorkspaceSnapshot.formatVersion) {
    return null;
  }
  return AuthorWorkspaceSnapshot.fromJson(json);
}
