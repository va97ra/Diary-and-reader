part of 'author_workspace_adaptive_test.dart';

void registerAdaptiveWorkflowScenarios() {
  testWidgets('renames a manuscript by tapping its title', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await tester.tap(find.byKey(const ValueKey('writer-book-title-action')));
    await tester.pumpAndSettle();
    expect(find.text('Название книги'), findsNWidgets(2));

    await tester.enterText(
      find.byKey(const ValueKey('writer-book-title-field')),
      'Моя первая книга',
    );
    await tester.tap(find.byKey(const ValueKey('writer-book-title-save')));
    await tester.pumpAndSettle();

    expect(controller.activeProject!.metadata.title, 'Моя первая книга');
    expect(find.text('Моя первая книга'), findsOneWidget);
    expect(find.byKey(const ValueKey('writer-save-status')), findsOneWidget);
    expect(find.text('Сохранено'), findsWidgets);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('renames and starts a chapter without a large mobile field', (
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

    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const ValueKey('writer-section-title-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('writer-section-title-field')),
      'Встреча',
    );
    await tester.tap(find.byKey(const ValueKey('writer-section-title-save')));
    await tester.pumpAndSettle();
    expect(controller.activeSection!.title, 'Встреча');

    final sectionCount = controller.activeProject!.sections.length;
    await tester.tap(find.byKey(const ValueKey('writer-structure-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navigator-new-chapter')), findsOneWidget);
    expect(find.byKey(const ValueKey('navigator-close')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('navigator-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navigator-new-chapter')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('writer-structure-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('navigator-new-chapter')));
    await tester.pumpAndSettle();

    expect(controller.activeProject!.sections.length, sectionCount + 1);
    expect(controller.activeSection!.title, 'Новая глава');
    expect(find.byType(TextField), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('finds and replaces text across a mobile manuscript', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent([
      {'insert': 'Старый дом и ещё один дом.\n'},
    ]);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    await tester.tap(find.byKey(const ValueKey('writer-more-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Поиск и замена в рукописи'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('manuscript-search-field')),
      'дом',
    );
    await tester.pumpAndSettle();
    expect(find.text('Найдено совпадений: 2'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('manuscript-replacement-field')),
      'сад',
    );
    await tester.tap(find.byKey(const ValueKey('replace-all-button')));
    await tester.pumpAndSettle();

    expect(
      richDocumentPlainText(controller.activeSection!.content),
      'Старый сад и ещё один сад.\n',
    );
    expect(find.text('Выполнено замен: 2'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('inserts an image into a mobile manuscript', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent([
      {'insert': 'Текст должен сохраниться.\nВторой абзац.\n'},
    ]);
    final imageGateway = _MemoryBookImageGateway(
      BookImageFile(
        name: 'pixel.png',
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, imageFileGateway: imageGateway),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    final firstParagraphEnd = 'Текст должен сохраниться.\n'.length;
    editor.controller.updateSelection(
      TextSelection.collapsed(offset: firstParagraphEnd),
      ChangeSource.local,
    );
    await tester.tap(find.byKey(const ValueKey('writer-formatting-action')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('insert-book-image-button')));
    await tester.pumpAndSettle();

    expect(imageGateway.openCount, 1);
    expect(controller.activeProject!.assets, hasLength(1));
    expect(
      jsonEncode(controller.activeSection!.content),
      contains('bookImage'),
    );
    expect(
      richDocumentPlainText(controller.activeSection!.content),
      'Текст должен сохраниться.\n\nВторой абзац.\n',
    );
    expect(find.text('Изображение добавлено в рукопись'), findsOneWidget);

    final assetId = controller.activeProject!.assets.single.id;
    editor.controller.updateSelection(
      TextSelection.collapsed(offset: editor.controller.document.length - 1),
      ChangeSource.local,
    );
    await tester.tap(find.byKey(ValueKey('book-image-action-$assetId')));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(editor.focusNode.canRequestFocus, isFalse);
    expect(
      find.byKey(const ValueKey('image-alignment-selector')),
      findsOneWidget,
    );
    await tester.tap(find.text('Справа'));
    expect(tester.testTextInput.isVisible, isFalse);
    await tester.enterText(
      find.byKey(const ValueKey('image-caption-field')),
      'Подпись к рисунку',
    );
    expect(tester.testTextInput.isVisible, isTrue);
    final sizeSlider = tester.widget<Slider>(
      find.byKey(const ValueKey('image-size-slider')),
    );
    sizeSlider.onChangeStart!(sizeSlider.value);
    sizeSlider.onChanged!(50);
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.text('50%'), findsOneWidget);
    expect(
      jsonEncode(controller.activeSection!.content),
      isNot(contains('Подпись к рисунку')),
      reason: 'Настройки должны оставаться локальными до закрытия окна.',
    );

    await tester.tap(find.byKey(const ValueKey('replace-book-image')));
    await tester.pumpAndSettle();
    expect(imageGateway.openCount, 2);
    expect(controller.activeProject!.assets, hasLength(1));
    await tester.tap(find.byKey(const ValueKey('image-settings-close')));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, isFalse);
    expect(
      tester
          .widget<QuillEditor>(find.byType(QuillEditor))
          .focusNode
          .canRequestFocus,
      isTrue,
    );
    expect(controller.activeProject!.assets, hasLength(2));
    final replacedOperation = controller.activeSection!.content.firstWhere(
      (operation) => operation['insert'] is Map,
    );
    final replacedCustom =
        (replacedOperation['insert'] as Map)['custom'] as String;
    final replacedId = BookImagePlacement.decode(
      jsonDecode(replacedCustom)['bookImage'] as String,
    ).assetId;
    expect(replacedId, isNot(assetId));
    final placement = BookImagePlacement.decode(
      jsonDecode(replacedCustom)['bookImage'] as String,
    );
    expect(placement.alignment, BookImageAlignment.right);
    expect(placement.widthPercent, 50);
    expect(placement.caption, 'Подпись к рисунку');
    final currentEditor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    currentEditor.controller.updateSelection(
      TextSelection.collapsed(
        offset: currentEditor.controller.document.length - 1,
      ),
      ChangeSource.local,
    );
    await tester.tap(find.byKey(ValueKey('book-image-action-$replacedId')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('move-image-to-cursor')));
    await tester.pumpAndSettle();
    expect(
      controller.activeSection!.content.indexWhere(
        (operation) => operation['insert'] is Map,
      ),
      greaterThan(0),
    );
    final movedImageOperation = controller.activeSection!.content.firstWhere(
      (operation) => operation['insert'] is Map,
    );
    final movedCustom =
        (movedImageOperation['insert'] as Map)['custom'] as String;
    final replacementId = BookImagePlacement.decode(
      jsonDecode(movedCustom)['bookImage'] as String,
    ).assetId;
    expect(replacementId, replacedId);
    await tester.tap(find.byKey(ValueKey('book-image-action-$replacementId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-book-image')));
    await tester.pumpAndSettle();
    expect(
      controller.activeSection!.content.where(
        (operation) => operation['insert'] is Map,
      ),
      isEmpty,
    );
    final remainingText = richDocumentPlainText(
      controller.activeSection!.content,
    );
    expect(remainingText, contains('Текст должен сохраниться.'));
    expect(remainingText, contains('Второй абзац.'));

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('inserts consecutive images at the text cursor', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent([
      {'insert': 'Начало.\nКонец.\n'},
    ]);
    final imageGateway = _MemoryBookImageGateway(
      BookImageFile(
        name: 'pixel.png',
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, imageFileGateway: imageGateway),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    editor.controller.updateSelection(
      TextSelection.collapsed(offset: 'Начало.\n'.length),
      ChangeSource.local,
    );

    for (var index = 0; index < 2; index++) {
      await tester.tap(find.byKey(const ValueKey('writer-formatting-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('insert-book-image-button')));
      await tester.pumpAndSettle();
    }

    final content = controller.activeSection!.content;
    final imageIndices = <int>[
      for (var index = 0; index < content.length; index++)
        if (content[index]['insert'] is Map) index,
    ];
    final endingIndex = content.indexWhere(
      (operation) =>
          operation['insert']?.toString().contains('Конец.') ?? false,
    );
    expect(imageIndices, hasLength(2));
    expect(imageIndices.every((index) => index > 0), isTrue);
    expect(
      imageIndices.every((index) => index < endingIndex),
      isTrue,
      reason: jsonEncode(content),
    );
    expect(imageGateway.openCount, 2);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('uploads and removes a manuscript cover', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    final imageGateway = _MemoryBookImageGateway(
      BookImageFile(
        name: 'cover.png',
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, imageFileGateway: imageGateway),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    await tester.tap(find.byKey(const ValueKey('writer-settings-action')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('choose-book-cover')),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const ValueKey('choose-book-cover')));
    await tester.pumpAndSettle();

    expect(controller.activeProject!.coverAsset, isNotNull);
    expect(imageGateway.openCount, 1);
    expect(find.byKey(const ValueKey('remove-book-cover')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('remove-book-cover')));
    await tester.pumpAndSettle();
    expect(controller.activeProject!.coverAsset, isNull);
    expect(find.byKey(const ValueKey('remove-book-cover')), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('inserts a page break without deleting selected text', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent([
      {'insert': 'Текст должен сохраниться.\n'},
    ]);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    editor.controller.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 5),
      ChangeSource.local,
    );
    await tester.tap(find.byKey(const ValueKey('writer-formatting-action')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('insert-book-page-break-button')),
    );
    await tester.pumpAndSettle();

    expect(
      jsonEncode(controller.activeSection!.content),
      contains('bookPageBreak'),
    );
    expect(
      richDocumentPlainText(controller.activeSection!.content),
      'Текст должен сохраниться.\n',
    );
    expect(
      find.text('Следующий текст начнётся с новой страницы'),
      findsOneWidget,
    );

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('imports an FB2 into the library and opens it in the reader', (
    tester,
  ) async {
    final repository = MemoryAuthorWorkspaceRepository();
    final controller = AuthorWorkspaceController(repository);
    await controller.load(preferredLanguage: 'ru');
    final gateway = _MemoryBookImportGateway(
      BookImportFile(
        name: 'other-book.fb2',
        bytes: File('test/fixtures/import_sample.fb2').readAsBytesSync(),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, importFileGateway: gateway),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-read-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-book-button')));
    await pumpUntilFound(tester, find.byType(BookReaderPage));

    expect(gateway.openCount, 1);
    expect(find.byType(BookReaderPage), findsOneWidget);
    expect(find.byKey(const ValueKey('book-image-asset-1')), findsOneWidget);
    expect(controller.projects, hasLength(2));
    expect(controller.activeProject!.kind, BookProjectKind.importedBook);
    final importedProjectId = controller.activeProject!.id;
    expect(
      repository.snapshot!.activeProject!.sourceFileName,
      'other-book.fb2',
    );

    Navigator.of(tester.element(find.byType(BookReaderPage))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reading-library')), findsOneWidget);
    expect(
      find.byKey(ValueKey('literia-project-$importedProjectId')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('book-cover-image')), findsWidgets);
    expect(find.byType(QuillEditor), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('exports the active project as EPUB', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    final saver = _MemoryBookExportSaver();
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, exportFileSaver: saver),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await _openExportSheet(tester);
    expect(find.text('Экспорт книги'), findsWidgets);
    expect(find.text('EPUB 3.3 (.epub)'), findsOneWidget);
    expect(find.text('Печатный PDF (.pdf)'), findsOneWidget);
    expect(find.text('Документ Word (.docx)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('export-book-epub')));
    await tester.pumpAndSettle();

    expect(saver.artifact?.extension, 'epub');
    expect(saver.artifact?.bytes, isNotEmpty);
    expect(saver.bookTitle, 'Новая книга');
    expect(find.text('Книга сохранена'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('exports the active project as DOCX', (tester) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    final saver = _MemoryBookExportSaver();
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, exportFileSaver: saver),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await _openExportSheet(tester);
    expect(find.byKey(const ValueKey('export-book-docx')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('export-book-docx')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-book-docx')));
    await tester.pumpAndSettle();

    expect(saver.artifact?.extension, 'docx');
    expect(saver.artifact?.mimeType, contains('wordprocessingml'));
    expect(saver.artifact?.bytes, isNotEmpty);
    expect(saver.bookTitle, 'Новая книга');
    expect(find.text('Книга сохранена'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('shows every export group and creates an archived FB2', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    final saver = _MemoryBookExportSaver();
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, exportFileSaver: saver),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await _openExportSheet(tester);
    expect(find.text('Для электронных читалок'), findsOneWidget);
    expect(find.text('Для печати и редактирования'), findsOneWidget);
    expect(find.text('Открытые текстовые форматы'), findsOneWidget);
    expect(find.byKey(const ValueKey('export-book-fb2')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-book-fb2-zip')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-book-html')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-book-markdown')), findsOneWidget);
    expect(find.byKey(const ValueKey('export-book-txt')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('export-book-fb2-zip')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-book-fb2-zip')));
    await tester.pumpAndSettle();

    expect(saver.artifact?.extension, 'fb2.zip');
    expect(saver.artifact?.mimeType, 'application/zip');
    expect(saver.artifact?.bytes, isNotEmpty);
    expect(find.text('Книга сохранена'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('opens PDF preview and reports generation errors', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      AuthorStudioApp(
        controller: controller,
        pdfFontLoader: _FailingPdfFontLoader(),
      ),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await _openExportSheet(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('export-book-pdf')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('export-book-pdf')));
    await tester.pumpAndSettle();

    expect(find.text('Предварительный просмотр PDF'), findsOneWidget);
    expect(
      find.text('Не удалось создать предварительный просмотр PDF'),
      findsOneWidget,
    );
    expect(find.text('Повторить'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('creates a named snapshot from the project data menu', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await tester.tap(find.byKey(const ValueKey('writer-panel-history')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Снимков пока нет'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('create-version-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('version-label-field')),
      'Перед финалом',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-create-version')));
    await tester.pumpAndSettle();

    expect(find.text('Перед финалом'), findsOneWidget);
    expect(await controller.listVersions(), hasLength(1));
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('exports and safely restores a portable project backup', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    final backupGateway = _MemoryProjectBackupGateway();
    await controller.load(preferredLanguage: 'ru');

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, backupFileGateway: backupGateway),
    );
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);

    await tester.tap(find.byKey(const ValueKey('writer-panel-backup')));
    await tester.pumpAndSettle();
    expect(backupGateway.savedArchive, isNotNull);
    expect(
      BookProjectArchiveCodec.decode(
        backupGateway.savedArchive!,
      ).metadata.title,
      'Новая книга',
    );

    final imported = controller.activeProject!.copyWith(
      metadata: const BookMetadata(title: 'Восстановленная книга'),
    );
    backupGateway.archiveToOpen = BookProjectArchiveCodec.encode(imported);
    await tester.tap(find.byKey(const ValueKey('writer-panel-restore')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-project-restore')));
    await tester.pumpAndSettle();

    expect(controller.activeProject!.metadata.title, 'Восстановленная книга');
    expect(await controller.listVersions(), hasLength(1));
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('refreshes the editor content after version restore', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(),
    );
    await controller.load(preferredLanguage: 'ru');
    controller.updateSectionContent(const <Map<String, dynamic>>[
      {'insert': 'Сохранённый вариант\n'},
    ]);
    final version = await controller.createVersion(label: 'Сохранённый');
    controller.updateSectionContent(const <Map<String, dynamic>>[
      {'insert': 'Заменяемый вариант\n'},
    ]);
    await controller.flush();

    await tester.binding.setSurfaceSize(const Size(1280, 900));
    await tester.pumpWidget(AuthorStudioApp(controller: controller));
    await tester.pumpAndSettle();
    await openLastManuscript(tester, controller);
    bool editorContains(String text) => tester
        .widgetList<QuillEditor>(find.byType(QuillEditor))
        .any(
          (editor) => editor.controller.document.toPlainText().contains(text),
        );
    expect(editorContains('Заменяемый вариант'), isTrue);

    await controller.restoreVersion(
      version!,
      safetyLabel: 'Перед восстановлением',
    );
    await tester.pumpAndSettle();

    expect(editorContains('Сохранённый вариант'), isTrue);
    expect(editorContains('Заменяемый вариант'), isFalse);
    await tester.binding.setSurfaceSize(null);
  });
}
