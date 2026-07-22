import 'dart:async';

import 'package:dnevnik/features/books/application/workspace_save_state.dart';
import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';

class WorkspacePersistenceCoordinator {
  WorkspacePersistenceCoordinator(
    this._repository,
    this._snapshot, {
    required this.onStateChanged,
    required this.saveDebounce,
    required this.maxSaveDelay,
  }) : assert(!saveDebounce.isNegative),
       assert(!maxSaveDelay.isNegative);

  final AuthorWorkspaceRepository _repository;
  final AuthorWorkspaceSnapshot Function() _snapshot;
  final VoidCallback onStateChanged;
  final Duration saveDebounce;
  final Duration maxSaveDelay;

  Future<void> _saveQueue = Future.value();
  Timer? _saveTimer;
  Timer? _maxSaveTimer;
  WorkspaceSaveState _saveState = WorkspaceSaveState.saved;
  int _changeRevision = 0;
  bool _isDisposed = false;

  WorkspaceSaveState get saveState => _saveState;

  Future<AuthorWorkspaceSnapshot?> load() => _repository.load();

  void markChanged() {
    _changeRevision++;
    _saveState = WorkspaceSaveState.saving;
  }

  void scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDebounce, () => unawaited(flush()));
    _maxSaveTimer ??= Timer(maxSaveDelay, () => unawaited(flush()));
  }

  Future<void> flush() async {
    _cancelTimers();
    final revision = _changeRevision;
    final snapshot = _snapshot();
    try {
      await _enqueueSave(snapshot);
      if (_isDisposed || revision != _changeRevision) return;
      _setSaveState(WorkspaceSaveState.saved);
    } catch (_) {
      if (_isDisposed || revision != _changeRevision) return;
      _setSaveState(WorkspaceSaveState.error);
    }
  }

  void dispose() {
    _isDisposed = true;
    _cancelTimers();
    unawaited(_enqueueSave(_snapshot()).catchError((_) {}));
  }

  void _cancelTimers() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _maxSaveTimer?.cancel();
    _maxSaveTimer = null;
  }

  void _setSaveState(WorkspaceSaveState state) {
    if (_saveState == state) return;
    _saveState = state;
    onStateChanged();
  }

  Future<void> _enqueueSave(AuthorWorkspaceSnapshot snapshot) {
    final save = _saveQueue.then((_) => _repository.save(snapshot));
    _saveQueue = save.catchError((_) {});
    return save;
  }
}

typedef VoidCallback = void Function();
