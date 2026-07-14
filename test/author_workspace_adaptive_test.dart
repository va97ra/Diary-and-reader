import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('shows manuscript and properties on desktop', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Рукопись'), findsOneWidget);
    expect(find.text('Свойства'), findsOneWidget);
    expect(find.byKey(const ValueKey('book-page-1')), findsOneWidget);
    expect(find.textContaining('A4 210×297 мм'), findsOneWidget);
    expect(find.text('Книжная'), findsOneWidget);
    expect(find.text('Альбомная'), findsOneWidget);
    expect(find.text('Слов: 0'), findsOneWidget);
    expect(find.text('Сохранено'), findsOneWidget);
    expect(find.text('Основной текст'), findsOneWidget);
    final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(editor.config.textSelectionThemeData?.cursorColor, AppTheme.ink);

    await tester.tap(find.text('Альбомная'));
    await tester.pumpAndSettle();
    expect(
      controller.activeProject!.layoutSettings.orientation,
      BookPageOrientation.landscape,
    );
    expect(find.textContaining('A4 297×210 мм'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('shows compact bottom navigation on mobile', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Редактор'), findsOneWidget);
    expect(find.textContaining('Лист A4 1 из 1'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });
}
