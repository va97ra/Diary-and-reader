import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('opens the adaptive author workspace', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Новая книга'), findsWidgets);
    expect(find.text('Рукопись'), findsOneWidget);
    expect(find.text('Глава 1'), findsWidgets);
  });
}
