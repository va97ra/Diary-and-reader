part of 'author_workspace_adaptive_test.dart';

void registerAdaptiveLayoutScenarios() {
  testWidgets('shows manuscript and properties on desktop', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    expect(find.byKey(const ValueKey('writer-context-bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('editor-bottom-navigation')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('book-page-1')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('writer-page-chapter-title')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('book-editor-status-bar')), findsNothing);
    expect(find.byKey(const ValueKey('writer-header-metrics')), findsOneWidget);
    expect(find.textContaining('Слов: 0 · Страница 1/1'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('writer-header-metrics')))
          .style
          ?.fontSize,
      11,
    );
    expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
    expect(find.text('Сохранено'), findsOneWidget);
    final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(editor.config.textSelectionThemeData?.cursorColor, AppTheme.ink);

    await tester.tap(find.byKey(const ValueKey('writer-settings-action')));
    await tester.pumpAndSettle();
    expect(find.text('Настройки рукописи'), findsOneWidget);
    expect(find.textContaining('A4 210×297 мм'), findsOneWidget);
    expect(find.text('Книжная'), findsOneWidget);
    expect(find.text('Альбомная'), findsOneWidget);
    await tester.ensureVisible(find.text('Альбомная'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Альбомная'));
    await tester.pumpAndSettle();
    expect(
      controller.activeProject!.layoutSettings.orientation,
      BookPageOrientation.landscape,
    );
    expect(find.textContaining('A4 297×210 мм'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('shows chapter title only in explicit A4 preview', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    expect(
      find.byKey(const ValueKey('writer-page-chapter-title')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('writer-settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('writer-a4-preview-action')));
    await pumpUntilFound(
      tester,
      find.byKey(const ValueKey('writer-page-chapter-title')),
    );
    expect(
      find.byKey(const ValueKey('writer-page-chapter-title')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('writer-settings-action')));
    await tester.pumpAndSettle();
    final titleSetting = find.byKey(
      ValueKey('${controller.activeProject!.id}-show-chapter-titles'),
    );
    await tester.ensureVisible(titleSetting);
    await tester.tap(titleSetting);
    await tester.pumpAndSettle();
    expect(
      controller.activeProject!.layoutSettings.showChapterTitlesInBody,
      isFalse,
    );
    expect(
      find.byKey(const ValueKey('writer-page-chapter-title')),
      findsNothing,
    );

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('shows compact bottom navigation on mobile', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    final mobileContent = <Map<String, dynamic>>[
      {'insert': 'Абзац, набранный на смартфоне.\n'},
    ];
    controller.updateSectionContent(mobileContent);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    expect(find.byKey(const ValueKey('writer-context-bar')), findsOneWidget);
    expect(find.text('Оформление'), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    expect(find.text('Ещё'), findsOneWidget);
    final moreButtonSize = tester.getSize(
      find.byKey(const ValueKey('writer-more-menu')),
    );
    expect(moreButtonSize.width, greaterThanOrEqualTo(48));
    expect(moreButtonSize.height, greaterThanOrEqualTo(48));
    expect(find.textContaining('Лист A4 1 из 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('book-editor-status-bar')), findsNothing);
    final headerMetrics = tester.widget<Text>(
      find.byKey(const ValueKey('writer-header-metrics')),
    );
    expect(headerMetrics.data, '4 слов · 1/1');
    expect(headerMetrics.style?.fontSize, 9.5);
    expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
    expect(find.text('Сохранено'), findsOneWidget);
    final writerAppBar = tester.widget<AppBar>(
      find.byKey(const ValueKey('writer-app-bar')),
    );
    expect(writerAppBar.backgroundColor, AppTheme.surface);
    expect(
      tester
          .widget<Material>(find.byKey(const ValueKey('writer-context-bar')))
          .color,
      AppTheme.surface,
    );
    final chapterTitle = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('writer-section-title-action')),
        matching: find.text('Глава 1'),
      ),
    );
    expect(chapterTitle.style?.fontSize, 14);
    final writingSurface = find.byKey(const ValueKey('mobile-writing-editor'));
    final writingRect = tester.getRect(writingSurface);
    expect(writingRect.left, 0);
    expect(writingRect.width, 390);
    expect(tester.widget<ColoredBox>(writingSurface).color, AppTheme.paper);
    expect(
      tester
          .widget<Padding>(find.byKey(const ValueKey('mobile-writing-content')))
          .padding,
      const EdgeInsets.fromLTRB(20, 12, 20, 10),
    );
    expect(find.byType(TextField), findsNothing);
    expect(
      find.byKey(const ValueKey('mobile-a4-preview-button')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('writer-hide-panels-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('editor-exit-focus-mode')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
    expect(find.byKey(const ValueKey('writer-context-bar')), findsNothing);
    expect(find.byKey(const ValueKey('book-editor-status-bar')), findsNothing);
    expect(find.byKey(const ValueKey('mobile-page-navigation')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('editor-exit-focus-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('writer-settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('writer-a4-preview-action')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('book-page-1')));
    expect(find.textContaining('Точная разметка A4'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('mobile-a4-page-preview')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('mobile-a4-edit-button')), findsOneWidget);

    final previewRect = tester.getRect(
      find.byKey(const ValueKey('book-page-1')),
    );
    expect(previewRect.width, greaterThan(340));

    await tester.tap(find.byKey(const ValueKey('mobile-a4-edit-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mobile-writing-editor')), findsOneWidget);
    expect(find.byKey(const ValueKey('book-page-1')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('writer-settings-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('writer-a4-preview-action')));
    await pumpUntilFound(tester, find.byKey(const ValueKey('book-page-1')));
    await tester.tap(find.byKey(const ValueKey('writer-hide-panels-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('editor-exit-focus-mode')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('book-page-1')), findsNothing);
    expect(find.byKey(const ValueKey('mobile-writing-editor')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('editor-exit-focus-mode')));
    await tester.pumpAndSettle();
    expect(
      jsonEncode(controller.activeSection!.content),
      jsonEncode(mobileContent),
    );
    expect(
      find.byKey(const ValueKey('mobile-page-navigation')),
      findsOneWidget,
    );

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'keeps autosave status visible on a tablet in both orientations',
    (tester) async {
      final controller = AuthorWorkspaceController(
        MemoryAuthorWorkspaceRepository(),
      );
      await controller.load(preferredLanguage: 'ru');
      await tester.binding.setSurfaceSize(const Size(800, 1280));
      await tester.pumpWidget(AuthorStudioApp(controller: controller));
      await tester.pumpAndSettle();
      await openLastManuscript(tester, controller);

      expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
      expect(find.text('Сохранено'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
      expect(find.text('Сохранено'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    },
  );
}
