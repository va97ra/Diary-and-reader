import 'dart:async';

import 'package:dnevnik/app/literia_book_details_page.dart';
import 'package:dnevnik/app/literia_book_storage_page.dart';
import 'package:dnevnik/app/literia_device_books_page.dart';
import 'package:dnevnik/app/literia_home_page.dart';
import 'package:dnevnik/app/literia_library_page.dart';
import 'package:dnevnik/app/literia_settings_page.dart';
import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_device_catalog.dart';
import 'package:dnevnik/features/books/application/book_image_file.dart';
import 'package:dnevnik/features/books/application/book_import_coordinator.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_pdf_font_assets.dart';
import 'package:dnevnik/features/books/application/book_project_archive_codec.dart';
import 'package:dnevnik/features/books/application/book_source_storage.dart';
import 'package:dnevnik/features/books/data/book_export_file_service.dart';
import 'package:dnevnik/features/books/data/book_image_file_service.dart';
import 'package:dnevnik/features/books/data/book_import_file_service.dart';
import 'package:dnevnik/features/books/data/book_pdf_asset_font_loader.dart';
import 'package:dnevnik/features/books/data/book_project_backup_file_service.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/presentation/author_workspace_page.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:flutter/material.dart';

class LiteriaHomeShell extends StatefulWidget {
  const LiteriaHomeShell({
    required this.controller,
    this.exportFileSaver = const BookExportFileService(),
    this.backupFileGateway = const BookProjectBackupFileService(),
    this.pdfFontLoader = const BookPdfAssetFontLoader(),
    this.importFileGateway = const BookImportFileService(),
    this.imageFileGateway = const BookImageFileService(),
    this.sourceStorage = const EphemeralBookSourceStorage(),
    this.deviceCatalog = const UnsupportedBookDeviceCatalog(),
    super.key,
  });

  final AuthorWorkspaceController controller;
  final BookExportFileSaver exportFileSaver;
  final BookProjectBackupFileGateway backupFileGateway;
  final BookPdfFontLoader pdfFontLoader;
  final BookImportFileGateway importFileGateway;
  final BookImageFileGateway imageFileGateway;
  final BookSourceStorage sourceStorage;
  final BookDeviceCatalogGateway deviceCatalog;

  @override
  State<LiteriaHomeShell> createState() => _LiteriaHomeShellState();
}

class _LiteriaHomeShellState extends State<LiteriaHomeShell> {
  bool _isImporting = false;
  bool _isImportProgressVisible = false;

  @override
  Widget build(BuildContext context) => LiteriaHomePage(
    lastManuscript: widget.controller.lastManuscript,
    lastReading: widget.controller.lastReading,
    onWrite: _openManuscriptLibrary,
    onRead: _openReadingLibrary,
    onSettings: _openSettings,
    onContinueWriting: () {
      final project = widget.controller.lastManuscript;
      if (project != null) _openManuscript(project);
    },
    onContinueReading: () {
      final project = widget.controller.lastReading;
      if (project != null) _openReader(project);
    },
    showOnboarding: !widget.controller.appPreferences.onboardingSeen,
    onDismissOnboarding: widget.controller.markOnboardingSeen,
  );

  Future<void> _openManuscriptLibrary() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => LiteriaLibraryPage(
        mode: LiteriaLibraryMode.manuscripts,
        controller: widget.controller,
        onPrimaryAction: _createManuscript,
        onOpen: _openManuscript,
        onDelete: _deleteProject,
        onAbout: _openBookDetails,
      ),
    ),
  );

  Future<void> _openReadingLibrary() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => LiteriaLibraryPage(
        mode: LiteriaLibraryMode.reading,
        controller: widget.controller,
        onPrimaryAction: _importBook,
        onFindOnDevice: widget.deviceCatalog.supportsFolderScanning
            ? _openDeviceBooks
            : null,
        countDeviceBooks: widget.deviceCatalog.supportsFolderScanning
            ? _countDeviceBooks
            : null,
        onOpen: _openReader,
        onDelete: _deleteProject,
        onAbout: _openBookDetails,
      ),
    ),
  );

  Future<void> _createManuscript() async {
    final project = widget.controller.addProject();
    await _openManuscript(project);
  }

  Future<void> _openManuscript(BookProject project) async {
    widget.controller.selectProject(project.id);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AuthorWorkspacePage(
          controller: widget.controller,
          exportFileSaver: widget.exportFileSaver,
          backupFileGateway: widget.backupFileGateway,
          pdfFontLoader: widget.pdfFontLoader,
          imageFileGateway: widget.imageFileGateway,
        ),
      ),
    );
    await widget.controller.flush();
  }

  Future<void> _importBook() async {
    if (_isImporting) return;
    _isImporting = true;
    try {
      final List<BookImportFile> files;
      if (widget.importFileGateway
          case final BookBatchImportFileGateway batch) {
        files = await batch.openMany();
      } else {
        final file = await widget.importFileGateway.open();
        files = file == null ? const [] : [file];
      }
      if (files.isEmpty || !mounted) return;
      _showImportProgress();
      final result = await _importFiles(files);
      if (!mounted) return;
      _hideImportProgress();
      await _finishImport(result);
    } on Exception {
      if (mounted) {
        _hideImportProgress();
        _showMessage(AppStrings.of(context).bookImportFailed);
      }
    } finally {
      _isImporting = false;
      if (mounted) _hideImportProgress();
    }
  }

  void _showImportProgress() {
    _isImportProgressVisible = true;
    final strings = AppStrings.of(context);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: BookLeatherDialog(
            title: const SizedBox.shrink(),
            content: Row(
              children: [
                const SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(width: 20),
                Expanded(child: Text(strings.importingBooks)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hideImportProgress() {
    if (!_isImportProgressVisible) return;
    _isImportProgressVisible = false;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  Future<BookImportBatchResult> _importFiles(List<BookImportFile> files) async {
    final available = await widget.deviceCatalog.availableBytes();
    return BookImportCoordinator(
      controller: widget.controller,
      sourceStorage: widget.sourceStorage,
    ).import(files, availableBytes: available);
  }

  Future<BookImportBatchResult> _importDeviceBooks(
    List<DeviceBookCandidate> candidates,
  ) async {
    final files = <BookImportFile>[];
    final materializeFailures = <BookImportItemResult>[];
    for (final candidate in candidates) {
      try {
        files.add(await widget.deviceCatalog.materialize(candidate));
      } on Exception {
        materializeFailures.add(
          BookImportItemResult(
            fileName: candidate.name,
            failure: BookImportItemFailure.storage,
          ),
        );
      }
    }
    final imported = await _importFiles(files);
    final result = BookImportBatchResult([
      ...imported.items,
      ...materializeFailures,
    ]);
    if (mounted && candidates.length == 1 && result.imported.length == 1) {
      await _openReader(result.imported.single);
    }
    return result;
  }

  Future<void> _finishImport(BookImportBatchResult result) async {
    final strings = AppStrings.of(context);
    if (result.items.length == 1 && result.conversionRequiredCount == 1) {
      _showMessage(strings.conversionRequired);
      return;
    }
    if (result.items.length == 1 && result.imported.length == 1) {
      _showMessage(strings.bookImported);
      await _openReader(result.imported.single);
      return;
    }
    final messages = <String>[
      if (result.imported.isNotEmpty)
        '${strings.bookImported}: ${result.imported.length}',
      if (result.duplicateCount > 0)
        '${strings.duplicateBooksSkipped}: ${result.duplicateCount}',
      if (result.failedCount > 0)
        '${strings.someBooksFailed}: ${result.failedCount}',
      if (result.conversionRequiredCount > 0) strings.conversionRequired,
    ];
    if (messages.isEmpty) messages.add(strings.bookImportFailed);
    _showMessage(messages.join(' · '));
  }

  Future<void> _openDeviceBooks() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => LiteriaDeviceBooksPage(
        controller: widget.controller,
        catalog: widget.deviceCatalog,
        onImport: _importDeviceBooks,
      ),
    ),
  );

  Future<int> _countDeviceBooks() async {
    final result = await widget.deviceCatalog.scan(
      widget.controller.appPreferences.bookScanFolders,
    );
    final importedUris = widget.controller.projects
        .where((project) => project.isReadOnly)
        .map((project) => project.sourceExternalUri)
        .where((uri) => uri.isNotEmpty)
        .toSet();
    return result.books
        .where((book) => !importedUris.contains(book.uri))
        .length;
  }

  Future<void> _openReader(BookProject project) async {
    widget.controller.selectProject(project.id);
    if (!mounted) return;
    final selected = widget.controller.activeProject;
    if (selected == null || selected.sections.isEmpty) return;
    widget.controller.beginReaderSession();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BookReaderPage(
          project: selected,
          readerSettings: widget.controller.readerSettings,
          onSettingsChanged:
              widget.controller.updateReaderSettingsDuringReading,
          onProgressChanged:
              widget.controller.updateReaderProgressDuringReading,
          onAnnotationsChanged:
              widget.controller.updateReaderAnnotationsDuringReading,
          onReadingTimeChanged: (duration) => widget.controller
              .recordReadingTimeDuringReading(selected.id, duration),
        ),
      ),
    );
    widget.controller.finishReaderSession();
    await widget.controller.flush();
  }

  Future<void> _openBookDetails(BookProject project) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => LiteriaBookDetailsPage(
            projectId: project.id,
            controller: widget.controller,
            onRead: _openReader,
          ),
        ),
      );

  Future<void> _deleteProject(BookProject project) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => BookLeatherDialog(
        title: Text(strings.deleteBook),
        content: Text(strings.deleteBookQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.deleteBook),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    widget.controller.deleteProject(project.id);
    await widget.controller.flush();
    if (project.isReadOnly) {
      await widget.sourceStorage.deleteProjectFiles(project);
    }
  }

  Future<void> _openSettings() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => LiteriaSettingsPage(
          themePreference: widget.controller.themePreference,
          languageCode: widget.controller.languageCode,
          canBackup: widget.controller.lastManuscript != null,
          onThemeChanged: widget.controller.setThemePreference,
          onLanguageChanged: widget.controller.setLanguage,
          onBackup: _backupLastManuscript,
          onRestore: _restoreProject,
          onOpenBookStorage: _openBookStorage,
          onShowOnboarding: _showOnboardingAgain,
        ),
      ),
    ),
  );

  void _openBookStorage() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LiteriaBookStoragePage(
          controller: widget.controller,
          sourceStorage: widget.sourceStorage,
          deviceCatalog: widget.deviceCatalog,
        ),
      ),
    );
  }

  void _showOnboardingAgain() {
    Navigator.of(context).pop();
    widget.controller.resetOnboarding();
  }

  Future<void> _backupLastManuscript() async {
    final strings = AppStrings.of(context);
    final project = widget.controller.lastManuscript;
    if (project == null) return;
    try {
      widget.controller.selectProject(project.id);
      await widget.controller.flush();
      final saved = await widget.backupFileGateway.save(
        archive: BookProjectArchiveCodec.encode(project),
        bookTitle: project.metadata.title,
      );
      if (mounted && saved) _showMessage(strings.projectBackupSaved);
    } on Exception {
      if (mounted) _showMessage(strings.projectBackupFailed);
    }
  }

  Future<void> _restoreProject() async {
    final strings = AppStrings.of(context);
    try {
      final encoded = await widget.backupFileGateway.open();
      if (encoded == null || !mounted) return;
      final restored = BookProjectArchiveCodec.decode(encoded);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => BookLeatherDialog(
          title: Text(strings.restoreProjectBackup),
          content: Text(
            '${restored.metadata.title}\n\n${strings.confirmProjectRestore}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(strings.restoreVersion),
            ),
          ],
        ),
      );
      if (!(confirmed ?? false) || !mounted) return;
      final target =
          widget.controller.lastManuscript ?? widget.controller.addProject();
      widget.controller.selectProject(target.id);
      await widget.controller.importProject(
        restored,
        safetyLabel: strings.safetyVersionLabel,
      );
      if (mounted) _showMessage(strings.projectRestored);
    } on FormatException {
      if (mounted) _showMessage(strings.projectRestoreFailed);
    } on Exception {
      if (mounted) _showMessage(strings.projectRestoreFailed);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
