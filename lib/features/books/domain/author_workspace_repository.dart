import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';

abstract interface class AuthorWorkspaceRepository {
  Future<AuthorWorkspaceSnapshot?> load();
  Future<void> save(AuthorWorkspaceSnapshot snapshot);
}
