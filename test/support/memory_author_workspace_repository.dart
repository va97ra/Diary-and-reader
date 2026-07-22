import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';

class MemoryAuthorWorkspaceRepository implements AuthorWorkspaceRepository {
  MemoryAuthorWorkspaceRepository({bool seedManuscript = true}) {
    if (!seedManuscript) return;
    final project = BookProject.create(
      title: 'Новая книга',
      chapterTitle: 'Глава 1',
      languageCode: 'ru',
    );
    snapshot = AuthorWorkspaceSnapshot(
      projects: [project],
      activeProjectId: project.id,
      languageCode: 'ru',
    );
  }

  AuthorWorkspaceSnapshot? snapshot;
  int saveCount = 0;

  @override
  Future<AuthorWorkspaceSnapshot?> load() async => snapshot;

  @override
  Future<void> save(AuthorWorkspaceSnapshot snapshot) async {
    saveCount++;
    this.snapshot = AuthorWorkspaceSnapshot.fromJson(snapshot.toJson());
  }
}
