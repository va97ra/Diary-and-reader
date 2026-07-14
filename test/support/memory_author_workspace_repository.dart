import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';

class MemoryAuthorWorkspaceRepository implements AuthorWorkspaceRepository {
  AuthorWorkspaceSnapshot? snapshot;

  @override
  Future<AuthorWorkspaceSnapshot?> load() async => snapshot;

  @override
  Future<void> save(AuthorWorkspaceSnapshot snapshot) async {
    this.snapshot = AuthorWorkspaceSnapshot.fromJson(snapshot.toJson());
  }
}
