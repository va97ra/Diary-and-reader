import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_author_workspace_repository.dart';

void main() {
  test('creates a book and persists chapter and scene hierarchy', () async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');

    final chapter = controller.activeSection!;
    controller.addSection(BookSectionType.scene);
    final scene = controller.activeSection!;
    await controller.flush();

    expect(controller.activeProject!.metadata.title, 'Новая книга');
    expect(scene.parentId, chapter.id);
    expect(repository.snapshot!.activeProject!.sections, hasLength(2));
  });
}
