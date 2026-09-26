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
    expect(find.byKey(const ValueKey('writer-context-bar')), findsNothing);
    expect(find.byKey(const ValueKey('writer-left-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('writer-right-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('writer-undo-action')), findsNothing);
    expect(find.byKey(const ValueKey('writer-redo-action')), findsNothing);
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
    expect(find.text('Слов: 0'), findsOneWidget);
    expect(find.text('Страница 1/1'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('writer-header-metrics')))
          .style
          ?.fontSize,
      10,
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
    expect(controller.activeProject!.layoutSettings.pageFormat.widthMm, 297);
    expect(controller.activeProject!.layoutSettings.pageFormat.heightMm, 210);

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
    expect(find.text('Ещё'), findsOneWidget);
    expect(find.text('Другие действия'), findsNothing);
    expect(find.byKey(const ValueKey('writer-undo-action')), findsNothing);
    expect(find.byKey(const ValueKey('writer-redo-action')), findsNothing);
    // Collapsing the interface sits in the header, as in the reader.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('writer-top-panel')),
        matching: find.byKey(const ValueKey('writer-hide-panels-button')),
      ),
      findsOneWidget,
    );
    final compactActions = [
      find.byKey(const ValueKey('writer-structure-action')),
      find.byKey(const ValueKey('writer-formatting-action')),
      find.byKey(const ValueKey('writer-picture-action')),
      find.byKey(const ValueKey('writer-settings-action')),
      find.byKey(const ValueKey('writer-more-menu')),
    ];
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('writer-context-bar')),
        matching: find.byType(BookPanelAction),
      ),
      findsNWidgets(compactActions.length),
    );
    for (var index = 1; index < compactActions.length; index++) {
      expect(
        tester.getCenter(compactActions[index - 1]).dx,
        lessThan(tester.getCenter(compactActions[index]).dx),
      );
    }
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
    expect(headerMetrics.data, 'Слов: 4 · Страница 1/1');
    expect(headerMetrics.style?.fontSize, 10);
    expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
    // The compact status is an icon; its label stays for screen readers.
    expect(find.text('Сохранено'), findsNothing);
    expect(find.bySemanticsLabel('Сохранено'), findsOneWidget);
    expect(find.byKey(const ValueKey('writer-app-bar')), findsNothing);
    expect(
      find.byKey(const ValueKey('book-compact-top-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('book-compact-bottom-panel')),
      findsOneWidget,
    );
    final chapterTitle = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('writer-section-title-action')),
        matching: find.text('Глава 1'),
      ),
    );
    expect(chapterTitle.style?.fontSize, 12);
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

    await tester.tap(find.byKey(const ValueKey('writer-structure-action')));
    await tester.pumpAndSettle();
    final structureSurface = tester.getRect(
      find.byType(BookLeatherModalSurface),
    );
    expect(structureSurface.height, lessThan(300));
    expect(find.text('Глава 1'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('navigator-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('writer-more-menu')));
    await tester.pumpAndSettle();
    expect(find.byType(BookLeatherModalSurface), findsOneWidget);
    final toolKeys = [
      const ValueKey('writer-panel-search'),
      const ValueKey('writer-panel-statistics'),
      const ValueKey('writer-panel-preview'),
      const ValueKey('writer-panel-export'),
      const ValueKey('writer-panel-history'),
      const ValueKey('writer-panel-trash'),
      const ValueKey('writer-panel-backup'),
      const ValueKey('writer-panel-restore'),
    ];
    final toolRects = [
      for (final key in toolKeys) tester.getRect(find.byKey(key)),
    ];
    for (var index = 1; index < toolRects.length; index++) {
      expect(toolRects[index].left, toolRects.first.left);
      expect(toolRects[index].top, greaterThan(toolRects[index - 1].bottom));
    }
    // The book's tools and those keeping the text safe are two groups.
    expect(find.text('КНИГА'), findsOneWidget);
    expect(find.text('СОХРАННОСТЬ ТЕКСТА'), findsOneWidget);
    expect(
      toolRects[4].top - toolRects[3].bottom,
      greaterThan(toolRects[1].top - toolRects[0].bottom),
    );
    expect(
      find.text('Файл со всей книгой, чтобы не потерять её'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(toolKeys.last));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

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

  testWidgets('groups writer formatting into a compact mobile grid', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    await tester.tap(find.byKey(const ValueKey('writer-formatting-action')));
    await tester.pumpAndSettle();

    final insertSection = find.byKey(
      const ValueKey('formatting-insert-section'),
    );
    final textSection = find.byKey(const ValueKey('formatting-text-section'));
    final paragraphSection = find.byKey(
      const ValueKey('formatting-paragraph-section'),
    );
    final manuscriptSection = find.byKey(
      const ValueKey('formatting-manuscript-section'),
    );
    expect(insertSection, findsOneWidget);
    expect(textSection, findsOneWidget);
    expect(paragraphSection, findsOneWidget);
    expect(manuscriptSection, findsOneWidget);
    expect(find.byType(QuillToolbarHistoryButton), findsNothing);

    final imageButton = find.byKey(const ValueKey('insert-book-image-button'));
    final pageBreakButton = find.byKey(
      const ValueKey('insert-book-page-break-button'),
    );
    expect(
      tester.getCenter(imageButton).dy,
      tester.getCenter(pageBreakButton).dy,
    );
    expect(
      tester.getCenter(imageButton).dx,
      lessThan(tester.getCenter(pageBreakButton).dx),
    );

    final fontFamily = find.byKey(const ValueKey('formatting-font-family'));
    final fontSize = find.byKey(const ValueKey('formatting-font-size'));
    expect(tester.getCenter(fontFamily).dy, tester.getCenter(fontSize).dy);
    expect(
      tester.getSize(fontFamily).width,
      greaterThan(tester.getSize(fontSize).width),
    );
    expect(
      tester.getTopLeft(textSection).dy,
      lessThan(tester.getTopLeft(paragraphSection).dy),
    );
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('groups manuscript settings into compact mobile cards', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    final project = controller.activeProject!;
    final section = controller.activeSection!;

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    await tester.tap(find.byKey(const ValueKey('writer-settings-action')));
    await tester.pumpAndSettle();

    final propertiesSection = find.byKey(
      const ValueKey('writer-properties-section'),
    );
    final pageLayoutSection = find.byKey(
      const ValueKey('writer-page-layout-section'),
    );
    expect(propertiesSection, findsOneWidget);
    expect(pageLayoutSection, findsOneWidget);

    final subtitle = find.byKey(ValueKey('${project.id}-subtitle'));
    final author = find.byKey(ValueKey('${project.id}-author'));
    expect(tester.getCenter(subtitle).dy, tester.getCenter(author).dy);

    await tester.ensureVisible(pageLayoutSection);
    await tester.pumpAndSettle();
    final marginFields = [
      find.byKey(ValueKey('${project.id}-margin-top')),
      find.byKey(ValueKey('${project.id}-margin-bottom')),
      find.byKey(ValueKey('${project.id}-margin-left')),
      find.byKey(ValueKey('${project.id}-margin-right')),
    ];
    final marginY = tester.getCenter(marginFields.first).dy;
    for (final field in marginFields.skip(1)) {
      expect(tester.getCenter(field).dy, marginY);
    }
    final landscapeOrientation = find.text('Альбомная');
    await tester.ensureVisible(landscapeOrientation);
    await tester.tap(landscapeOrientation);
    await tester.pumpAndSettle();
    expect(
      controller.activeProject!.layoutSettings.orientation,
      BookPageOrientation.landscape,
    );
    expect(
      tester
          .widget<SegmentedButton<BookPageOrientation>>(
            find.descendant(
              of: find.byKey(ValueKey('${project.id}-page-orientation')),
              matching: find.byType(SegmentedButton<BookPageOrientation>),
            ),
          )
          .selected,
      {BookPageOrientation.landscape},
    );
    expect(controller.activeProject!.layoutSettings.pageFormat.widthMm, 297);
    expect(controller.activeProject!.layoutSettings.pageFormat.heightMm, 210);

    // The chapter's own progress comes last, apart from the book.
    final status = find.byKey(ValueKey('${section.id}-status'));
    await tester.scrollUntilVisible(
      status,
      200,
      scrollable: find
          .descendant(
            of: find.byType(BookPropertiesPanel),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    final target = find.byKey(ValueKey('${section.id}-word-target'));
    expect(tester.getCenter(status).dy, tester.getCenter(target).dy);
    expect(tester.takeException(), isNull);

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
      expect(find.byKey(const ValueKey('writer-left-panel')), findsOneWidget);
      expect(find.byKey(const ValueKey('writer-right-panel')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('book-compact-bottom-panel')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(const Size(1280, 800));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
      expect(find.text('Сохранено'), findsOneWidget);
      expect(find.byKey(const ValueKey('writer-left-panel')), findsOneWidget);
      expect(find.byKey(const ValueKey('writer-right-panel')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.setSurfaceSize(null);
    },
  );
}
