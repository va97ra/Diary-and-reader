# Карта кода «Литерии»

Как устроено приложение и где что лежит. **Читать перед любой работой в
проекте, обновлять после каждой правки** — правило в `CLAUDE.md`.

Карта из двух частей:

- **этот файл** — описание вручную: что за что отвечает, как проходят
  сценарии, какие классы и методы участвуют;
- **`docs/CODE_SYMBOLS.md`** — указатель всех классов, методов, констант и
  тестов **с номерами строк** и первой фразой doc-комментария. Генерируется:

  ```
  dart run tool/code_map.dart
  ```

  Запускать после каждой правки кода. Ищите по имени из этого файла,
  например `textSpanBuilder`, — там будет строка.

Ниже пути `presentation/`, `application/`, `domain/`, `data/` — внутри
`lib/features/books/`. Запись `Класс.метод` — имя для поиска в
`CODE_SYMBOLS.md`.

Обновлено: 2026-10-04, версия 1.0.5+6.

---

## 1. Быстрый указатель «где искать»

| Нужно | Файл → символ |
|---|---|
| Версия | `pubspec.yaml` `version:` + `lib/app/literia_version.dart` `literiaVersion` (тест сверяет) |
| Тексты интерфейса | `lib/core/l10n/app_strings.dart` (геттер) + `app_string_values_ru.dart` + `app_string_values_en.dart` (ключ в обоих) |
| Цвета и тема | `lib/core/theme/app_theme.dart` `AppTheme`; кожа панелей — `widgets/book_adaptive_control_shell.dart` `BookLeatherColors` |
| Ширина «телефон / планшет» | `widgets/book_adaptive_control_shell.dart` `bookControlBreakpoint` = 700 |
| Кирпичики шторок настроек | `widgets/book_settings_controls.dart`: `BookSettingsCard`, `BookSettingsRow(flex:)`, `BookCompactChoice`, `BookSettingSwitch`, `BookCompactDropdown`, `bookNumberChoices`, `bookNamedChoices`, `bookSettingNumber` |
| Кнопки и подписи боковых панелей | `widgets/book_adaptive_control_shell.dart`: `BookPanelAction`, `BookPanelSectionLabel`, `BookWholeWordsText` (слово не рвётся — текст уменьшается), ширина панелей — `_sidePanelWidths` (+ вырез камеры) |
| Открыть шторку / диалог | `widgets/book_leather_modal.dart`: `showBookLeatherBottomSheet`, `BookLeatherModalHeader`, `BookLeatherDialog`, `bookLeatherModalTheme` |
| Меню выделенных слов в писалке | `widgets/book_editor_context_menu.dart`: `BookEditorContextMenu` (копировать/вставить сверху, «Вставить картинку») + `BookSelectionFormattingBar` под словами (Ж, К, Ч, З, цвет с палитрой в самой панели, очистить); на компьютере — `BookSelectionBarTrigger` (панель сразу после выделения мышью); подключается через `BookImageEditingScope.contextMenuBuilder` |
| Состояние всей программы | `application/author_workspace_controller.dart` `AuthorWorkspaceController` |
| Модель книги | `domain/book_project.dart` `BookProject`; глава — `domain/book_section.dart` `BookSection` |
| Текст главы | `domain/rich_document.dart` — Quill Delta, список операций `{insert, attributes}` |
| Писалка (экран) | `presentation/author_workspace_page.dart` `_AuthorWorkspacePageState` |
| «Оформление» | `widgets/book_formatting_sheet.dart` `BookFormattingSheet` |
| «Настройки» писалки | `widgets/book_properties_panel.dart` `BookPropertiesPanel` + `widgets/book_page_settings_section.dart` |
| Как рисуется абзац в писалке | `presentation/book_typography.dart` `BookTypography.editorStyles`, `.textSpanBuilder`, `.indentsFirstLine` |
| Стили абзаца | `presentation/book_paragraph_style_actions.dart` `BookParagraphStyleActions`; список — `domain/book_paragraph_style.dart` |
| Настройки текста книги | `domain/book_paragraph_settings.dart` `BookParagraphSettings`, `bookIndentLevelEm`, `bookDefaultTextSize`, `bookFontFamilies`, `bookFontSizesPt` |
| Читалка (экран) | `presentation/reader/book_reader_page.dart` `_BookReaderPageState` |
| «Настройки чтения» | `presentation/reader/book_reader_settings_sheet.dart`; модель — `domain/book_reader_settings.dart` |
| Как читалка рисует текст | `presentation/reader/book_reader_typography.dart` `BookReaderTypography.block`, `.run` |
| Экспорт | `application/book_*_exporter.dart`; общая модель — `application/book_export_content.dart` `BookExportContentParser`, `BookExportBlock.indentsFirstLine` |
| Импорт | `application/book_import_coordinator.dart` `BookImportCoordinator`; парсеры `*_book_format_parser.dart` |
| Сохранение на диск | `data/file_author_workspace_repository.dart` `FileAuthorWorkspaceRepository` |
| Настройки приложения | `lib/app/literia_settings_page.dart` `LiteriaSettingsPage` |
| Сборка релиза | `tool/build_android_release.ps1`, `tool/package_windows_release.ps1`; итог — `RuStore Release\<версия+сборка>\` |

---

## 2. Слои и зависимости

```
lib/main.dart ─► lib/app (экраны верхнего уровня, навигация)
                   │
                   ▼
   features/books/presentation  (виджеты, шторки, писалка, читалка)
                   │  только через AuthorWorkspaceController
                   ▼
   features/books/application   (контроллер, сценарии, экспорт, импорт)
                   │  только через интерфейсы
                   ▼
   features/books/domain        (модели, без Flutter-виджетов)
                   ▲
   features/books/data          (файлы, SharedPreferences, платформа)
```

- `data/*_factory.dart` выбирает реализацию по платформе: `*_io.dart` —
  Windows/Android/iOS (файлы), `*_preferences.dart` / `*_stub.dart` — веб.
- Интерфейсы хранилищ: `domain/author_workspace_repository.dart`,
  `domain/book_version_repository.dart`; источники импортированных книг —
  `application/book_source_storage.dart`.

---

## 3. Запуск

`lib/main.dart` `main`:
1. `createAuthorWorkspaceRepository` (файлы или SharedPreferences),
   `createBookVersionRepository`, `createBookSourceStorage`,
   `createBookDeviceCatalog`.
2. На Windows — `startLiteriaDesktopShell` (трей, панель у часов).
3. `runApp(AuthorStudioApp(...))`.

`lib/app/author_studio_app.dart` `AuthorStudioApp`:
- `ListenableBuilder` слушает контроллер и перестраивает весь `MaterialApp`
  (язык, тема). Поэтому шторки, которые зовут `AppStrings.of(context)`, тоже
  обновляются после изменений в контроллере.
- `_WorkspaceSaveLifecycle` сохраняет работу при сворачивании
  (`didChangeAppLifecycleState` → `controller.flush`).
- `home:` — `LiteriaHomeShell`.

`lib/app/literia_home_shell.dart` `_LiteriaHomeShellState` — вся навигация:
- `_openManuscriptLibrary`, `_openReadingLibrary` → `LiteriaLibraryPage`;
- `_createManuscript`, `_openManuscript` → `AuthorWorkspacePage` (писалка);
- `_openReader` → `BookReaderPage` (читалка для импортированных книг);
- импорт: `_importBook`, `_importFiles`, `_importFileStream`,
  `_importDeviceBooks`, `_scanAndImportDeviceBooks`, `_scanAutomaticSources`,
  прогресс — `_showImportProgress` / `_hideImportProgress`;
- `_openSettings` → `LiteriaSettingsPage` (в `ListenableBuilder`);
- `_backupLastManuscript`, `_restoreProject`, `_openBookStorage`,
  `_openBookDetails`, `_deleteProject`.

---

## 4. Данные

### 4.1 Книга
`domain/book_project.dart` `BookProject`:
- `kind` — `BookProjectKind.manuscript` (своя рукопись) или
  `importedBook` (только чтение, `isReadOnly`);
- `metadata` (`domain/book_metadata.dart`), `sections` (дерево:
  `BookSectionType.part/chapter/scene`, `parentId`, `childrenOf`),
  `activeSectionId`, `assets` (картинки, обложка — `coverAsset`);
- `paragraphSettings` — вид текста (шрифт, размер, межстрочный, красная
  строка, интервалы, пресет);
- `layoutSettings` (`domain/book_layout_settings.dart`) — ориентация, поля,
  режим листов, заголовки глав в тексте; `pageFormat` — размеры в
  логических пикселях (`domain/book_page_format.dart`: мм/пт ↔ px при
  96 dpi);
- `readerProgress`, `readerAnnotations` (закладки, выделения, заметки),
  корзины `sectionTrash` / `textTrash`, статистика письма, `libraryState`;
- миграции при чтении JSON: `_migrateOversizedPlainTextSections`
  (делит огромные txt-главы), версии формата
  `_currentDocumentFormatVersion`.

### 4.2 Текст главы — Quill Delta
`domain/rich_document.dart`: `RichDocument` = `List<Map<String, dynamic>>`.
Атрибуты, которые понимает вся программа (писалка, читалка, экспорт):

| Атрибут / вставка | Где задаётся | Значение |
|---|---|---|
| `bold`, `italic`, `underline`, `strike`, `color`, `font`, `size` | «Оформление» → «Выделенный текст» | на словах; `size` — логические px писалки (12 пт = 16 px) |
| `align` (`center`/`right`/`justify`) | кнопки выравнивания | на `\n` строки |
| `indent` (1–5) | кнопки «отступ» | уровень, 1 уровень = `bookIndentLevelEm` размера текста |
| `list` (`ordered`/`bullet`/`checked`) | кнопки списков | |
| `header` (1–3), `blockquote` | стиль абзаца | |
| `bookParagraphStyle` | `BookParagraphStyleActions.apply` | имя стиля: `verse`, `epigraph`, `quote`, `sceneBreak`, … |
| `line-height` | только старые документы | больше не задаётся; стиль абзаца его сбрасывает |
| `{insert: {bookImage: …}}` | картинки | `domain/book_image_placement.dart` `BookImagePlacement` (выравнивание, ширина %, подпись) |
| `{insert: {bookPageBreak: …}}` | «Разрыв страницы» | `richDocumentIsPageBreak` |

### 4.3 Где хранятся настройки
- Вид текста и страниц — **в книге** (`paragraphSettings`, `layoutSettings`).
- Настройки читалки, тема, язык, обучение — **общие для приложения**:
  `domain/literia_app_preferences.dart` `LiteriaAppPreferences`
  (`readerSettings`, `themePreference`, `languageCode`).

---

## 5. Состояние и сохранение

`application/author_workspace_controller.dart` `AuthorWorkspaceController`
(`ChangeNotifier`) — единственная точка изменений:
- загрузка: `load`; выбор: `selectProject`, `selectSection`;
- книги: `addProject`, `addImportedBook`, `deleteProject`, `importProject`;
- главы: `addSection`, `moveSection`, `moveSectionToTarget`,
  `deleteSectionSafely`, `restoreDeletedSection`, `emptyTrash`;
- текст: `updateSectionContent`, `updateSectionTitle`,
  `replaceAllInManuscriptSafely`, `restoreDeletedText`;
- оформление: `updateParagraphSettings`, `updateLayoutSettings`,
  `updateMetadata`, `setCoverAsset`, `addAsset`;
- читалка: `updateReaderSettings` / `...DuringReading`,
  `updateReaderProgress`, `updateReaderAnnotations`, `beginReaderSession`,
  `finishReaderSession` (во время чтения уведомления подавлены, чтобы не
  перестраивать весь `MaterialApp`);
- приложение: `setLanguage` (+ `_localizeDefaultTitles`),
  `setThemePreference`;
- версии: `listVersions`, `createVersion`, `restoreVersion`, `deleteVersion`;
- сохранить сейчас: `flush`.

Правка проходит так: `_changed` → `WorkspacePersistenceCoordinator`
(`application/workspace_persistence_coordinator.dart`): `markChanged`,
`scheduleSave` (пауза 350 мс, не дольше 2 с) → `repository.save`.
Состояние сохранения — `WorkspaceSaveState` (`saved/saving/error`),
показ — `widgets/book_save_status.dart`.

Файлы на диске (`data/file_author_workspace_repository.dart`):
`author-workspace-v2.json` (основной), `.pending` (запись идёт),
`.rollback`, две копии `backup-1/2.json` раз в 5 минут. `load` берёт первый
целый файл из этого списка. Старые данные «Дневника» переносит
`application/legacy_diary_migrator.dart`.

Именованные версии книги: `application/workspace_version_coordinator.dart`
+ `data/file_book_version_repository.dart`. Резервная копия книги в файл
`.dnevnik-book.json`: `application/book_project_archive_codec.dart`,
`data/book_project_backup_file_service.dart`.

---

## 6. Писалка

### 6.1 Экран
`presentation/author_workspace_page.dart` `_AuthorWorkspacePageState`:
- каркас — `BookAdaptiveControlShell`: телефон (< 700 px) —
  `_buildCompactWriterTop` + `_buildCompactWriterBottom`; планшет/Windows и
  телефон боком — `_buildWideWriterStart` + `_buildWideWriterEnd` (панели
  128/176 px плюс вырез на их стороне);
- кнопки нижней панели телефона: «Структура» `_showManuscript`,
  «Оформление» `_showFormatting`, «Картинка» `_showAddPicture`,
  «Настройки» `_showWriterSettings`, «Ещё» `_showWorkspaceTools`;
- «Ещё» — `BookWorkspaceAction` (`widgets/book_workspace_action.dart`):
  поиск `_showManuscriptSearch`, статистика `_showWritingStatistics`,
  предпросмотр `_openReader`, экспорт `_showExportSheet`, история
  `_showVersionHistory`, корзина `_showSectionTrash`, копия
  `_backupProject`, восстановление `_restoreProjectBackup`;
- фокус-режим `_toggleFocusMode`, A4 на телефоне `_toggleA4Preview`,
  `_usesPagedLayout` (листы: всегда на широком экране, на телефоне — в A4);
- переименование `_renameBook`, `_renameSection`.

### 6.2 Редактор
- `widgets/book_section_editor.dart` `BookSectionEditorState` — редактор
  главы: по странице A4 свой `QuillController`
  (`_createPageControllers`), разбивка — `_schedulePagination` →
  `_measureCurrentDocument` (скрытый редактор-«линейка» той же вёрстки) →
  `application/book_page_paginator.dart`. Вставка картинки из буфера —
  `_pasteClipboardImage`. Переход к найденному — `revealTextRange`.
- Прокрутка к курсору в режиме листов — `_revealCaret` (из слушателя
  страницы и `didChangeMetrics`, когда появилась клавиатура или повернулся
  экран): у Quill там `scrollable: false`, и сам он не прокручивает.
- Отрисовка листов: `widgets/book_editor_page_stage.dart`,
  `widgets/book_page_canvas.dart` (лист A4 с полями и номером; заголовок
  главы — поле без заливки и рамки темы, как текст на бумаге),
  `widgets/book_mobile_editor.dart` (крупный режим телефона).
- Оба редактора берут вид из `BookTypography.editorStyles` и
  `BookTypography.textSpanBuilder`.

### 6.3 Как рисуется абзац (`presentation/book_typography.dart`)
- Quill кладёт абзац с `align`, `indent`, `list` или `line-height` в «блок».
  Отступы и интервалы блока берутся из `align` / `indent` / `lists`, а не из
  `paragraph`. Поэтому `editorStyles` даёт всем видам блоков одинаковые
  интервалы «Сверху/Снизу» (`VerticalSpacing` и `lineSpacing`) и нулевой
  горизонтальный отступ.
- **Красная строка** — `textSpanBuilder`: первая буква абзаца рисуется
  `WidgetSpan`-ом с отступом слева. Она занимает ровно один символ, поэтому
  курсор и выделение не сдвигаются. Не применяется к суррогатным парам,
  буквам с комбинирующими знаками и переносу строки (`_drawsAlone`), а
  также к строкам, которые не являются основным текстом слева или по
  ширине (`indentsFirstLine`).
- **Уровень отступа** — `_indentWidth` (подключён через
  `lists.indentWidthBuilder`): Quill даёт 1 размер текста, мы добавляем до
  `bookIndentLevelEm`.
- Списки и их номера — шрифтом книги (`lists`, `leading`).
- Заголовки h1–h3, цитата, заглушка — `_block`.
- Межстрочный интервал одного абзаца убран: блок «только с `line-height`»
  Quill рисует без интервала по краям, и абзац слипался со следующим.

### 6.4 «Оформление» (`widgets/book_formatting_sheet.dart`)
Открывает `_showFormatting`; `onApplied` закрывает шторку после **любого**
изменения (кнопки Quill — через `afterButtonPressed`, списки — `_applying`).
- «Выделенный текст»: только шрифт и размер слов — `_FormattingDropdown` →
  `controller.formatSelection`; подсказка `selectionBarHint`: Ж, К, Ч, З,
  цвет и «очистить» — в панели под выделенными словами (6.8).
- «Абзац»: стиль — `widgets/book_paragraph_style_selector.dart` →
  `BookParagraphStyleActions.apply`; одна строка `_EvenToolbarRow`:
  4 выравнивания (у «по ширине» своя подсказка `alignJustify` — у Quill
  «по ширине окна»), 2 отступа, 2 списка.
- Шрифт и размер слов без своего значения показываются из
  `workspaceController.activeProject!.paragraphSettings`.
- «Вставить»: картинка (`_showAddPicture`), разрыв (`_insertPageBreak`).
- «Вся книга»: `widgets/book_paragraph_settings_section.dart` — пресет,
  шрифт, размер, межстрочный, красная строка / сверху / снизу (ряд с
  `flex: [5, 3, 3]`) → `controller.updateParagraphSettings`.

### 6.5 Стили абзаца (`presentation/book_paragraph_style_actions.dart`)
- `current` — какой стиль под курсором; `apply` — снимает
  `_clearedBlockAttributes` (в том числе `line-height`) и ставит
  `_visualAttributes` + `bookParagraphStyle`.
- Стихи = `blockquote` + по центру; эпиграф = `blockquote` + справа;
  сцена — по центру, `_insertSceneMarkerIntoEmptyLine` ставит `* * *`.
- `BookQuoteBlockExitRule` — Enter в стихах: одна пустая строка — новая
  строфа, вторая — выход в обычный текст. `repairQuoteBlocks` чинит старые
  документы.

### 6.6 «Настройки» писалки
`_showWriterSettings` → `widgets/book_properties_panel.dart`
`BookPropertiesPanel`:
- «О книге»: название, подзаголовок, автор, описание (`_PropertyField` →
  `controller.updateMetadata`), обложка `_CoverSettings`;
- «Страницы»: `widgets/book_page_settings_section.dart` — кнопка A4/обычный
  вид, режим листов, ориентация, пресет полей, 4 поля, заголовки глав.
  `onChanged` закрывает шторку после изменения;
- «Текущая глава»: статус черновика, цель по словам (шторку не закрывают).

### 6.7 Картинки
- Вставка: `_showAddPicture` → `_insertImage` / `_pasteClipboardImage` →
  `_insertImageAsset`; файлы — `data/book_image_file_service.dart`, буфер —
  `data/book_clipboard_image_service.dart`.
- На странице: `widgets/book_image_embed_builder.dart`
  `BookImageEmbedBuilder`, выделение и меню —
  `widgets/book_image_editing_scope.dart`.
- Окно картинки: `_showImageSettings` →
  `widgets/book_image_settings_sheet.dart` (черновик применяется при
  закрытии); правки документа — `application/book_image_document_editing.dart`.

### 6.8 Меню выделенных слов
`widgets/book_editor_context_menu.dart`:
- `BookEditorContextMenu` — то, что Quill показывает при выделении:
  системное меню «Копировать / Вставить» над словами (плюс «Вставить
  картинку», если в буфере картинка) и под словами
  `BookSelectionFormattingBar`;
- `_BelowSelectionLayout` ставит панель под словами, ниже ручек выделения;
  если меню уехало под слова (нет места сверху) — ещё ниже; если нет места
  снизу — над словами и меню;
- `BookSelectionFormattingBar`: Ж, К, Ч, З переключаются (`_toggle`), цвет
  открывает палитру прямо в панели (без всплывающего меню — так выделение
  не теряется), «Без цвета» снимает цвет, «очистить» (`_clear`) снимает
  только оформление слов, не абзаца. Панель остаётся после нажатия, можно
  сделать и жирным, и курсивом. Цвета — `BookTextColors.palette`, кружок —
  `BookTextColorSwatch(size:)`, значок кнопки — `BookTextColorIcon` (буква
  с радужной полоской или полоской цвета слов) из
  `widgets/book_text_color_menu.dart`;
- `BookSelectionBarTrigger` оборачивает оба редактора (`BookPageCanvas`,
  `BookMobileEditor`): на Windows/macOS/Linux после выделения мышью
  (протянуть, двойной щелчок) вызывает `showToolbar` с `barOnly` — меню
  показывает одну панель, без копировать/вставить; правый клик — всё меню.
  Ключ телефонного редактора — свой (`_mobileEditorKey` в
  `BookSectionEditorState`): общий с листами перенёс бы состояние
  редактора листа в телефонный при закрытии A4.

### 6.9 Остальное в писалке
- Структура книги: `widgets/book_navigator.dart`; дерево —
  `application/section_tree_editor.dart`.
- Поиск и замена: `presentation/book_manuscript_search_sheet.dart`,
  `application/book_manuscript_search.dart`.
- Корзина: `presentation/book_trash_sheet.dart`,
  `application/book_deleted_text.dart`.
- История версий: `presentation/book_version_history_sheet.dart`.
- Статистика: `presentation/book_writing_statistics_sheet.dart`,
  `domain/book_writing_state.dart`, `domain/manuscript_statistics.dart`.
- Экспорт: `presentation/book_export_sheet.dart` → `_exportArtifact`;
  предпросмотр PDF — `presentation/book_pdf_preview_page.dart`.

---

## 7. Читалка

### 7.1 Экран
`presentation/reader/book_reader_page.dart` `_BookReaderPageState`:
- панели парят над текстом (`overlayPanels`): телефон —
  `_buildCompactReaderTop` / `_buildCompactReaderBottom`, широкий экран —
  `_buildWideReaderStart` / `_buildWideReaderEnd`; при чтении панели
  прячутся (`_handleUserNavigation`), касание по центру —
  `_handleReadingSurfaceTap`;
- кнопки: оглавление `_showContents`, поиск `_showSearch`, настройки
  `_showSettings`, озвучка `_toggleSpeech`, закладка `_toggleBookmark`;
- переходы: `_goToLocation`, `_goToNextSection`, `_goToPreviousSectionEnd`,
  прогресс — `_handleSectionProgress` → `_saveProgress`;
- выделение: `_handleTextSelection` → панель
  `reader/book_reader_selection_bar.dart`: цвет (`_saveHighlight`), цитата,
  копия, словарь/перевод (`_openSelectionLookup`), заметка;
- экспорт заметок: `_showAnnotationExport`.

### 7.2 Как текст попадает на экран
1. `reader/book_reader_document_model.dart` `BookReaderDocumentParser.parse`
   — Delta → `BookReaderBlock` (тип, выравнивание, уровень отступа) и
   `BookReaderTextRun` (жирный, цвет, размер…). Шрифт слов и `line-height`
   абзацев читалка не берёт — у неё свои шрифт и межстрочный интервал.
2. Переносы: `application/book_reader_hyphenation.dart`
   (`BookReaderDisplayDocument`, мягкие дефисы), дефис в конце строки —
   `reader/book_reader_soft_hyphens.dart`.
3. Вид блока и слов: `reader/book_reader_typography.dart`:
   `BookReaderTypography.block` (размер, межстрочный из настроек, интервалы,
   отступы по типу блока, по ширине, `textScale`), `.run` (размер слов, заданный автором,
   умножается на `textScale`, то есть «Размер» читалки / 16 px).
4. Режимы: `reader/book_reader_section_view.dart`
   `_BookReaderSectionViewState` с частями `book_reader_section_continuous.dart`
   (лента), `book_reader_section_pagination.dart` (страницы, разворот),
   `book_reader_section_document.dart`; в режиме «Страница» на телефоне
   страница стоит между парящими панелями (`readingInsets`, те же отступы,
   что у «Ленты»); раскладка страниц —
   `reader/book_reader_layout_engine.dart`; отрисовка —
   `reader/book_reader_document_view.dart`, `book_reader_continuous_view.dart`,
   `book_reader_page_stage.dart`, `book_reader_page_card.dart`.
5. Цвета темы: `reader/book_reader_palette.dart`; выделения —
   `reader/book_reader_highlight_style.dart`.

### 7.3 «Настройки чтения»
`_showSettings` → `reader/book_reader_settings_sheet.dart`:
- `_change(settings, hide:)` → `widget.onChanged` →
  `_applyReaderSettings` → `controller.updateReaderSettings` (общие для
  всех книг);
- вид меняется → шторка закрывается (режим, тема, шрифт, размер списком
  12–32, насыщенность, межстрочный, по ширине, переносы, поля, ширина,
  сброс); «Управление» и «Чтение вслух» — `hide: false`;
- разворот скрыт на телефоне в портрете, ширина текста — только от 600 px.

### 7.4 Озвучка, поиск, заметки
- Озвучка: `application/book_speech_engine.dart`
  (`FlutterBookSpeechEngine`, плагин `third_party/flutter_tts`), фразы —
  `application/book_speech_segmenter.dart`, кнопки —
  `reader/book_reader_speech_controls.dart`; в странице —
  `_startSpeechAt`, `_speakNextSegment`, `_refreshSpeechAfterSettingsChange`.
- Поиск: `reader/book_reader_search_sheet.dart` +
  `application/book_reader_search.dart`.
- Закладки и заметки: `domain/book_reader_annotations.dart`,
  `reader/book_reader_annotation_actions.dart`,
  `reader/book_reader_annotations_panel.dart`,
  `reader/book_reader_note_dialog.dart`; выгрузка —
  `application/book_reader_annotation_exporter.dart`.
- Оглавление и закладки сбоку: `reader/book_reader_navigation_panel.dart`,
  `reader/book_reader_contents.dart`.

---

## 8. Библиотека и импорт

- Главная: `lib/app/literia_home_page.dart` («Писать», «Читать»,
  «Продолжить»).
- Библиотеки: `lib/app/literia_library_page.dart`
  (`LiteriaLibraryMode.manuscripts/reading`; кожаная панель поиска до краёв,
  карточки отступают от выреза через `sides`),
  `literia_library_controls.dart` (поиск, сортировка, фильтры),
  `literia_library_items.dart` (карточки); запросы —
  `application/book_library_query.dart`; статус чтения —
  `domain/book_library_state.dart`.
- Карточка книги: `lib/app/literia_book_details_page.dart`; место на
  устройстве: `literia_book_storage_page.dart`; книги на устройстве:
  `literia_device_books_page.dart` + `application/book_device_catalog.dart`.
- Импорт: `BookImportCoordinator.importStream` → `BookImportParser` →
  парсер по формату (`BookImportFormat`: epub, fb2, fb2Zip, txt, rtf, docx,
  mobi): `epub_book_format_parser.dart`, `fb2_book_format_parser.dart`,
  `mobi_book_format_parser.dart`, `text_document_book_format_parser.dart`;
  XML → Delta — `xml_book_content_converter.dart`, кодировки —
  `xml_text_decoder.dart`; исходник книги хранится в
  `data/file_book_source_storage.dart`; открытие —
  `application/book_reading_session_loader.dart`.

---

## 9. Экспорт

Все форматы читают главы через
`application/book_export_content.dart` `BookExportContentParser.parse` →
`BookExportBlock` (тип, выравнивание, `indent`, `lineHeight`,
`semanticStyle`, `indentsFirstLine`) и `BookExportTextRun`.

| Формат | Файлы |
|---|---|
| EPUB 3.3 | `book_epub_exporter.dart` (CSS, OPF, NAV) + `epub_rich_text_renderer.dart` (XHTML) |
| FB2 / FB2.ZIP | `book_fb2_exporter.dart` + `fb2_rich_text_renderer.dart` |
| PDF | `book_pdf_exporter.dart` + `book_pdf_content_renderer.dart` (абзацы, отступы, списки, картинки) + `book_pdf_font_assets.dart` (PT Serif из `assets/fonts`) |
| DOCX | `book_docx_exporter.dart` + `book_docx_content_renderer.dart` (`_paragraphProperties`: стиль, `w:ind`, интервалы) + `book_docx_package_parts.dart` (стили: `BodyText` с красной строкой) |
| HTML | `book_html_exporter.dart` (+ рендер EPUB) |
| Markdown, TXT | `book_markdown_exporter.dart` + `markdown_rich_text_renderer.dart`; `book_txt_exporter.dart` + `plain_text_rich_renderer.dart` |

Общие правила, одинаковые с писалкой: красная строка только у
`indentsFirstLine`; уровень отступа = `bookIndentLevelEm` × размер текста
(в DOCX: пт × 1,5 × 20 твипов). Сохранение файла —
`data/book_export_file_service.dart`.

---

## 10. Настройки приложения, Windows, платформа

- `lib/app/literia_settings_page.dart`: тема, язык, резервная копия,
  восстановление, хранилище книг, справка, версия (`literiaVersion`).
- Windows: `lib/app/desktop/literia_desktop_shell.dart` (интерфейс),
  `literia_desktop_shell_io.dart` (`_WindowsDesktopShell`: трей, панель у
  часов, запоминание окна), `literia_desktop_panel_frame.dart`; установщик —
  `windows/installer/literia.iss`.
- Android: `android/app/src/main/AndroidManifest.xml`; подпись —
  `android/key.properties` (не в git).

---

## 11. Тесты

- Помощники: `test/support/literia_test_navigation.dart`
  (`openLastManuscript`, `openReaderPreview`, `toggleReaderPanels`,
  `pumpUntilFound`), `test/support/memory_author_workspace_repository.dart`.
- Полный список тестов с номерами строк — в конце `docs/CODE_SYMBOLS.md`.
- Где что проверяется:
  - вид абзаца в писалке — `test/book_typography_test.dart`;
  - «Оформление» — `test/book_formatting_sheet_test.dart`;
  - раскладка писалки и «Настройки» — `test/author_workspace_adaptive_*`;
  - «Настройки чтения» — `test/book_reader_settings_sheet_test.dart`,
    `test/book_reader_settings_test.dart`;
  - вид текста в читалке — `test/book_reader_verse_and_color_test.dart`,
    `test/book_reader_paged_view_test.dart`, `test/book_reader_page_test.dart`;
  - экспорт — `test/book_*_exporter_test.dart`,
    `test/book_verse_and_color_export_test.dart`;
  - импорт — `test/book_import_*_test.dart`.

---

## 12. Сборка и релиз

- Проверки: `dart format lib test tool`, `flutter analyze`, `flutter test`
  (CI — `.github/workflows/ci.yml`).
- Android: `tool/build_android_release.ps1` (AAB) + `flutter build apk
  --release` (универсальный APK); подпись проверять `apksigner verify
  --print-certs` (SHA-256 сертификата `9008b351…8425b`).
- Windows: `tool/package_windows_release.ps1` (ZIP + установщик Inno
  Setup в `dist/`). Если сборка падает на `cpp_client_wrapper`, удалить
  `windows/flutter/ephemeral` (сгенерированный, вне git).
- Готовые файлы — `RuStore Release\<версия+сборка>\`: `literia-<v>.aab/.apk`,
  `-windows-x64-setup.exe/.zip`, `README.txt`, `RELEASE_NOTES.txt`,
  `SHA256SUMS.txt`.

---

## 13. Договорённости

- Без дублей; мёртвый код удалять в той же правке.
- Шторка, закрывающая текст, после изменения вида сама убирается.
- Писалка, читалка и экспорт должны совпадать по красной строке, отступам
  и интервалам.
- Новая строка интерфейса — геттер в `app_strings.dart` и ключ в
  `app_string_values_ru.dart` и `_en.dart`.

---

## Журнал правок карты

- 2026-10-04 — карта создана; добавлены `bookIndentLevelEm`,
  `bookDefaultTextSize`, `BookTypography.textSpanBuilder/indentsFirstLine`,
  `BookExportBlock.indentsFirstLine`, `BookSettingsRow(flex:)`; удалены
  `BookWriterContextBar`, `BookSettingStepper`, выбор межстрочного
  интервала для одного абзаца в «Оформлении».
- 2026-10-04 — карта расписана подробно по сценариям; добавлены генератор
  `tool/code_map.dart` и указатель `docs/CODE_SYMBOLS.md` с номерами строк.
- 2026-10-04 — «Оформление» без Ж/К/Ч/З/цвета/очистить (они в панели
  под словами), подсказка `selectionBarHint`; «очистить» в панели;
  `BookSelectionBarTrigger` для компьютера; `BookTextColorIcon`;
  удалены `_TextColorButton`, `bookTextColorMenuItems`; тесты в
  `test/book_selection_formatting_test.dart`.
- 2026-10-04 — новое меню выделенных слов
  `widgets/book_editor_context_menu.dart` (перенесено из
  `book_image_editing_scope.dart` + панель форматирования под словами);
  строки `boldText`, `italicText`, `underlineText`, `strikeText`; удалены
  `textColorAction`, `undo`, `redo`; тест
  `test/book_selection_formatting_test.dart`.
- 2026-10-04 — читалка «Страница»: страница между панелями
  (`BookReaderSectionView.build` + `readingInsets`); заголовок главы на
  листе без серой плашки темы (`BookPageCanvas`); тест в
  `test/book_reader_paged_view_test.dart` (размер через `tester.view`, так
  как читалка меряет экран по `MediaQuery`).
- 2026-10-04 — проверка на телефоне: `_revealCaret` в
  `BookSectionEditorState`, `_sidePanelWidths` и `BookWholeWordsText` в
  панелях, отступы от выреза в библиотеке; тесты
  `test/book_panel_layout_test.dart` и прокрутка в
  `test/book_pagination_widget_test.dart`.
- 2026-10-04 — читалка: межстрочный интервал из настроек для всех абзацев,
  поле `BookReaderBlock.lineHeight` удалено; у `BookFormattingSheet` убран
  параметр `paragraphSettings`; строка `alignJustify`; README обновлён.
