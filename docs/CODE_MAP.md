# Карта кода «Литерии»

Где что лежит, чтобы не искать. **Читать перед любой работой в проекте,
обновлять после каждой правки** (новый файл, переезд логики, удаление —
сразу отметить здесь). Правило записано в `CLAUDE.md`.

Последнее обновление: 2026-10-04, версия 1.0.5+6.

## Быстрый указатель «где искать»

| Что нужно | Где |
|---|---|
| Версия приложения | `pubspec.yaml` (`version:`) + `lib/app/literia_version.dart` (тест сверяет их) |
| Все тексты интерфейса (ru/en) | `lib/core/l10n/app_strings.dart` (геттеры) + `app_string_values_ru.dart` / `_en.dart` |
| Цвета, тема | `lib/core/theme/app_theme.dart`; кожаные панели — `BookLeatherColors` в `widgets/book_adaptive_control_shell.dart` |
| Общие кирпичики шторок настроек (карточка, ряд, выпадающий список, переключатель) | `presentation/widgets/book_settings_controls.dart` |
| Как открывается любая шторка (тёмный фон, кожа) | `presentation/widgets/book_leather_modal.dart` (`showBookLeatherBottomSheet`) |
| Писалка: экран, панели, открытие шторок | `presentation/author_workspace_page.dart` (`_showFormatting`, `_showWriterSettings`, `_showWorkspaceTools`) |
| Писалка: шторка «Оформление» | `presentation/widgets/book_formatting_sheet.dart` (+ `book_paragraph_style_selector.dart`, `book_paragraph_settings_section.dart`, `book_text_color_menu.dart`) |
| Писалка: шторка «Настройки» (свойства книги, страница, глава) | `presentation/widgets/book_properties_panel.dart` + `book_page_settings_section.dart` |
| Как писалка рисует абзацы (красная строка, интервалы, шаг отступа, списки) | `presentation/book_typography.dart` (`editorStyles`, `textSpanBuilder`, `indentsFirstLine`) |
| Стили абзаца (заголовки, цитата, эпиграф, стихи, сцена) | `presentation/book_paragraph_style_actions.dart` + `domain/book_paragraph_style.dart` |
| Настройки текста книги (шрифт, размер, красная строка, интервалы, пресеты) | `domain/book_paragraph_settings.dart` (там же `bookIndentLevelEm`, `bookDefaultTextSize`) |
| Поля, ориентация, режим листов | `domain/book_layout_settings.dart`, `domain/book_page_format.dart`, `domain/book_page_view_mode.dart` |
| Редактор главы, разбивка на страницы A4 | `presentation/widgets/book_section_editor.dart`, `book_page_canvas.dart`, `book_mobile_editor.dart`, `application/book_page_paginator.dart`, `book_pagination_measurement.dart` |
| Картинки в тексте | `widgets/book_image_embed_builder.dart`, `book_image_editing_scope.dart`, `book_image_settings_sheet.dart`, `application/book_image_document_editing.dart`, `domain/book_image_placement.dart` |
| Читалка: экран | `presentation/reader/book_reader_page.dart` (`_showSettings`, `_applyReaderSettings`) |
| Читалка: шторка «Настройки чтения» | `presentation/reader/book_reader_settings_sheet.dart`; модель — `domain/book_reader_settings.dart` |
| Читалка: шрифты/размеры/отступы блоков и слов | `presentation/reader/book_reader_typography.dart` |
| Читалка: разбор документа и раскладка страниц | `reader/book_reader_document_model.dart`, `book_reader_layout_engine.dart`, `book_reader_section_*.dart`, `book_reader_continuous_view.dart` |
| Экспорт (EPUB, FB2, PDF, DOCX, HTML, MD, TXT) | `application/book_*_exporter.dart`; общая модель блоков — `application/book_export_content.dart` (`indentsFirstLine`) |
| Импорт книг | `application/book_import_*.dart`, `*_book_format_parser.dart`, `xml_book_content_converter.dart` |
| Состояние всей студии, сохранение | `application/author_workspace_controller.dart`, `workspace_persistence_coordinator.dart`, `data/file_author_workspace_repository.dart` |
| Настройки приложения (тема, язык, резервная копия) | `lib/app/literia_settings_page.dart` |
| Сборка релиза | `tool/build_android_release.ps1`, `tool/package_windows_release.ps1`, `docs/release-checklist.md`; готовые файлы — `RuStore Release\<версия+сборка>\` |

Пути `presentation/`, `application/`, `domain/`, `data/` ниже — внутри
`lib/features/books/`.

## Корень проекта

- `lib/` — код приложения (см. ниже).
- `test/` — тесты (`flutter test`), помощники в `test/support/`
  (`literia_test_navigation.dart` — открыть рукопись/читалку,
  `memory_author_workspace_repository.dart` — хранилище в памяти),
  `test/fixtures/` — образцы книг.
- `integration_test/critical_data_flows_test.dart` — сквозные сценарии.
- `assets/` — шрифты PT Serif (для PDF), фон и картинки главного экрана,
  иконка, текстура кожи.
- `third_party/flutter_tts/` — локальная копия плагина озвучки.
- `android/`, `windows/` (в т.ч. `windows/installer/`), `web/`, `ios/` —
  платформы.
- `tool/` — скрипты сборки и ключа подписи Android, упаковки Windows.
- `docs/` — `release-checklist.md`, `implementation_plan.md`, эта карта.
- `.github/workflows/ci.yml` — анализ, тесты, сборки на CI.
- `RuStore Release/` — готовые релизы (в git не входит).

## lib/

- `main.dart` — запуск: хранилища, трей Windows, `AuthorStudioApp`.

### lib/app — оболочка и экраны верхнего уровня
- `author_studio_app.dart` — `MaterialApp`, тема, язык, сохранение при
  сворачивании.
- `literia_home_shell.dart` — навигация: главная, библиотеки, настройки,
  импорт, резервные копии, открытие писалки/читалки.
- `literia_home_page.dart` — главный экран «Писать / Читать».
- `literia_library_page.dart`, `literia_library_controls.dart`,
  `literia_library_items.dart` — списки рукописей и книг, поиск, фильтры.
- `literia_book_details_page.dart` — карточка книги.
- `literia_book_storage_page.dart` — место на устройстве.
- `literia_device_books_page.dart` — поиск книг на устройстве.
- `literia_settings_page.dart` — настройки приложения.
- `literia_version.dart` — строка версии.
- `desktop/` — трей, окно-панель и режимы окна на Windows
  (`*_io.dart` — реализация, `*_stub.dart` — заглушка для веба).

### lib/core
- `l10n/` — строки ru/en (`AppStrings.of(context).xxx`).
- `theme/app_theme.dart` — светлая/тёмная тема, цвета бумаги и чернил.

### lib/features/books/domain — модели без Flutter-логики
- `book_project.dart` — книга целиком (рукопись или импорт), всё её
  состояние; `book_section.dart` — часть/глава/сцена.
- `book_paragraph_settings.dart` — вид текста книги, списки шрифтов и
  размеров, шаг отступа, размер текста по умолчанию.
- `book_paragraph_style.dart` — виды абзацев.
- `book_layout_settings.dart`, `book_page_format.dart`,
  `book_page_view_mode.dart` — страница, мм↔пиксели↔пункты.
- `book_reader_settings.dart` — настройки читалки.
- `book_reader_annotations.dart`, `book_reader_progress.dart`,
  `book_reading_progress.dart` — закладки, заметки, прогресс.
- `book_metadata.dart`, `book_asset.dart`, `book_image_placement.dart`.
- `rich_document.dart` — текст в формате Quill Delta (список операций).
- `book_text_trash.dart`, `book_section_trash.dart` — корзины.
- `book_writing_state.dart`, `manuscript_*statistics.dart` — статистика.
- `book_library_state.dart`, `book_scan_folder.dart`,
  `literia_app_preferences.dart` — библиотека и настройки приложения.
- `author_workspace_repository.dart`, `book_version_repository.dart` —
  интерфейсы хранилищ; `author_workspace_snapshot.dart` — снимок данных.
- Мелочи: `book_chapter_heading.dart`, `book_default_titles.dart`,
  `book_plain_text_chunk.dart`, `book_project_version.dart`,
  `unique_timestamp.dart`.

### lib/features/books/application — сценарии и преобразования
- Состояние: `author_workspace_controller.dart` (главный контроллер),
  `manuscript_project_editor.dart`, `section_tree_editor.dart`,
  `workspace_library_editor.dart`, `workspace_persistence_coordinator.dart`,
  `workspace_version_coordinator.dart`, `workspace_save_state.dart`,
  `transient_book_version_repository.dart`.
- Экспорт: `book_export_content.dart` (общая модель блоков),
  `book_epub_exporter.dart` + `epub_rich_text_renderer.dart`,
  `book_fb2_exporter.dart` + `fb2_rich_text_renderer.dart`,
  `book_pdf_exporter.dart` + `book_pdf_content_renderer.dart` +
  `book_pdf_font_assets.dart`, `book_docx_exporter.dart` +
  `book_docx_content_renderer.dart` + `book_docx_package_parts.dart`,
  `book_html_exporter.dart`, `book_markdown_exporter.dart` +
  `markdown_rich_text_renderer.dart`, `book_txt_exporter.dart` +
  `plain_text_rich_renderer.dart`, `book_export_artifact.dart`.
- Импорт: `book_import_coordinator.dart`, `book_import_parser.dart`,
  `book_import_parsing_support.dart`, `book_import_file.dart`,
  `book_format_parser.dart`, `epub_book_format_parser.dart`,
  `fb2_book_format_parser.dart`, `mobi_book_format_parser.dart`,
  `text_document_book_format_parser.dart`, `xml_book_content_converter.dart`,
  `xml_text_decoder.dart`, `book_source_storage.dart`,
  `book_device_catalog.dart`, `book_catalog_project.dart`.
- Читалка: `book_reading_session_loader.dart`, `book_reader_search.dart`,
  `book_reader_hyphenation.dart`, `book_reader_text_anchor.dart`,
  `book_reader_annotation_exporter.dart`, `book_reader_external_lookup.dart`,
  `book_speech_engine.dart`, `book_speech_segmenter.dart`.
- Писалка: `book_page_paginator.dart`, `book_pagination_measurement.dart`,
  `book_manuscript_search.dart`, `book_deleted_text.dart`,
  `book_image_document_editing.dart`, `book_image_file.dart`,
  `book_section_outline.dart`, `book_cover_thumbnail.dart`.
- Резервные копии и миграция: `book_project_archive_codec.dart`,
  `legacy_diary_migrator.dart`, `book_library_query.dart`.

### lib/features/books/data — файлы, диск, платформа
- Хранилище студии: `file_author_workspace_repository.dart` (нативно),
  `preferences_author_workspace_repository.dart` (веб),
  `workspace_repository_factory*.dart` (выбор по платформе).
- Версии: `file_book_version_repository.dart`,
  `preferences_book_version_repository.dart`,
  `book_version_repository_factory*.dart`.
- Исходники импортированных книг: `file_book_source_storage.dart`,
  `book_source_storage_factory*.dart`.
- Файлы и буфер обмена: `book_export_file_service.dart`,
  `book_import_file_service.dart`, `book_image_file_service.dart`,
  `book_clipboard_image_service.dart`, `book_project_backup_file_service.dart`,
  `book_reader_annotation_file_service.dart`, `book_pdf_asset_font_loader.dart`,
  `book_device_catalog_factory*.dart`.

### lib/features/books/presentation — экраны и виджеты
- `author_workspace_page.dart` — писалка целиком: панели телефона/планшета,
  все шторки, картинки, экспорт, предпросмотр.
- `book_typography.dart` — вид текста в редакторе (см. указатель).
- `book_paragraph_style_actions.dart` — применение стилей абзаца,
  правило выхода из цитаты/стихов по Enter.
- Шторки писалки: `book_export_sheet.dart`, `book_manuscript_search_sheet.dart`,
  `book_trash_sheet.dart`, `book_version_history_sheet.dart`,
  `book_writing_statistics_sheet.dart`; `book_pdf_preview_page.dart` —
  предпросмотр PDF; `book_text_colors.dart` — палитра цвета текста.
- `widgets/`:
  - каркас: `book_adaptive_control_shell.dart` (панели, кожа, отступы
    телефона/планшета), `book_leather_modal.dart`, `book_settings_controls.dart`,
    `book_sheet_keyboard_dismiss.dart`, `book_empty_state.dart`,
    `book_save_status.dart`, `book_focus_mode_bar.dart`,
    `book_workspace_action.dart` (пункты меню «Ещё»);
  - редактор: `book_section_editor.dart`, `book_editor_page_stage.dart`,
    `book_page_canvas.dart`, `book_mobile_editor.dart`,
    `book_editor_metrics.dart`, `book_page_break_embed_builder.dart`;
  - оформление: `book_formatting_sheet.dart`,
    `book_paragraph_style_selector.dart`,
    `book_paragraph_settings_section.dart`, `book_text_color_menu.dart`;
  - настройки: `book_properties_panel.dart`, `book_page_settings_section.dart`,
    `book_metadata_editor_dialog.dart`, `book_rename_title_dialog.dart`;
  - структура книги: `book_navigator.dart`; обложка: `book_cover_view.dart`;
  - картинки: `book_image_embed_builder.dart`, `book_image_editing_scope.dart`,
    `book_image_settings_sheet.dart`.
- `reader/`:
  - экран и панели: `book_reader_page.dart`, `book_reader_context_bar.dart`,
    `book_reader_selection_bar.dart`, `book_reader_speech_controls.dart`,
    `book_reader_progress_rail.dart`, `book_reader_navigation_panel.dart`,
    `book_reader_contents.dart`, `book_reader_annotations_panel.dart`;
  - шторки и диалоги: `book_reader_settings_sheet.dart`,
    `book_reader_search_sheet.dart`, `book_reader_annotation_export_sheet.dart`,
    `book_reader_note_dialog.dart`;
  - текст и страницы: `book_reader_document_model.dart` (Delta → блоки),
    `book_reader_typography.dart`, `book_reader_layout_engine.dart`,
    `book_reader_document_view.dart`, `book_reader_section_view.dart` +
    `_continuous` / `_document` / `_pagination` (части одного состояния),
    `book_reader_continuous_view.dart`, `book_reader_page_stage.dart`,
    `book_reader_page_card.dart`, `book_reader_soft_hyphens.dart`,
    `book_reader_palette.dart`, `book_reader_highlight_style.dart`;
  - выделение и заметки: `book_reader_text_selection.dart`,
    `book_reader_selection_resolver.dart`, `book_reader_annotation_actions.dart`,
    `book_reader_location_callback.dart`.

### lib/features/books/legacy
- `legacy_diary_snapshot.dart` — формат данных ранней версии «Дневник».

## Важные договорённости

- Без дублей: переиспользовать существующий помощник, мёртвый код удалять.
- Шторки, закрывающие текст, после изменения вида сами убираются
  (`onApplied` в «Оформлении», `onChanged` в разделе «Страница»,
  `_change(..., hide:)` в «Настройках чтения»).
- Красная строка — только первая строка абзаца, для основного текста слева
  или по ширине; одинаково в писалке (`BookTypography.indentsFirstLine`) и
  в экспорте (`BookExportBlock.indentsFirstLine`).
- Уровень отступа абзаца — `bookIndentLevelEm` (1,5 размера текста) везде.
- Перед сдачей: `dart format lib test`, `flutter analyze`, `flutter test`.

## Журнал правок карты

- 2026-10-04 — карта создана; добавлены `bookIndentLevelEm`,
  `bookDefaultTextSize`, `BookTypography.textSpanBuilder/indentsFirstLine`,
  `BookExportBlock.indentsFirstLine`, `BookSettingsRow(flex:)`; удалены
  `BookWriterContextBar`, `BookSettingStepper`, выбор межстрочного
  интервала для одного абзаца в «Оформлении».
