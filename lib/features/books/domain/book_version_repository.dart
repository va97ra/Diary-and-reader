import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_project_version.dart';

abstract interface class BookVersionRepository {
  Future<List<BookProjectVersion>> list(String projectId);

  Future<BookProjectVersion> create({
    required BookProject project,
    String? label,
  });

  Future<void> delete({required String projectId, required String versionId});
}
