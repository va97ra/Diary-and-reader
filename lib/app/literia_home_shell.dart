import 'dart:async';

import 'package:dnevnik/app/literia_book_details_page.dart';
import 'package:dnevnik/app/literia_book_storage_page.dart';
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
import 'package:dnevnik/features/books/application/book_reading_session_loader.dart';
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
        onScanDeviceBooks: widget.deviceCatalog.supportsFolderScanning
            ? _scanAndImportDeviceBooks
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

  void _showImportProgress({String? message}) {
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
                Expanded(child: Text(message ?? strings.importingBooks)),
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

  Future<BookImportBatchResult> _importFileStream(
    Stream<BookImportFile> files,
  ) async {
    final available = await widget.deviceCatalog.availableBytes();
    return BookImportCoordinator(
      controller: widget.controller,
      sourceStorage: widget.sourceStorage,
    ).importStream(files, availableBytes: available);
  }

  Future<BookImportBatchResult> _importDeviceBooks(
    List<DeviceBookCandidate> candidates, {
    bool openSingle = true,
  }) async {
    final materializeFailures = <BookImportItemResult>[];
    Stream<BookImportFile> materializeSequentially() async* {
      for (final candidate in candidates) {
        try {
          yield await widget.deviceCatalog.materialize(candidate);
        } on Exception {
          materializeFailures.add(
            BookImportItemResult(
              fileName: candidate.name,
              failure: BookImportItemFailure.storage,
            ),
          );
        }
      }
    }

    final imported = await _importFileStream(materializeSequentially());
    final result = BookImportBatchResult([
      ...imported.items,
      ...materializeFailures,
    ]);
    if (openSingle &&
        mounted &&
        candidates.length == 1 &&
        result.imported.length == 1) {
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

  Future<void> _scanAndImportDeviceBooks() async {
    if (_isImporting) return;
    _isImporting = true;
    final strings = AppStrings.of(context);
    try {
      var scanResult = await _scanAutomaticSources();
      if (scanResult == null || !mounted) return;

      if (scanResult.inaccessibleFolderUris.isNotEmpty) {
        final repaired = await _repairScanFolderAccess(
          scanResult.inaccessibleFolderUris.toSet(),
        );
        if (!mounted) return;
        if (repaired) {
          scanResult = await _scanAutomaticSources();
          if (scanResult == null || !mounted) return;
        }
      }

      final importedSources = widget.controller.projects
          .where((project) => project.isReadOnly)
          .where((project) => project.sourceExternalUri.isNotEmpty)
          .map(
            (project) =>
                '${project.sourceExternalUri}\n${project.sourceFileSize}\n'
                '${project.sourceModifiedMillis}',
          )
          .toSet();
      final candidates = scanResult.books
          .where(
            (book) => !importedSources.contains(
              '${book.uri}\n${book.sizeBytes}\n'
              '${book.modifiedAt?.millisecondsSinceEpoch ?? 0}',
            ),
          )
          .toList();
      if (candidates.isEmpty) {
        _showMessage(strings.noNewBooks);
        return;
      }

      _showImportProgress(message: strings.scanningBooks);
      final result = await _importDeviceBooks(candidates, openSingle: false);
      if (!mounted) return;
      _hideImportProgress();
      _showScanResult(result);
    } on Exception {
      if (mounted) {
        _hideImportProgress();
        _showMessage(strings.scanFailed);
      }
    } finally {
      _isImporting = false;
      if (mounted) _hideImportProgress();
    }
  }

  Future<DeviceBookScanResult?> _scanAutomaticSources() async {
    var downloads = const DeviceBookScanResult();
    if (widget.deviceCatalog case final BookDownloadsCatalogGateway scanner) {
      final hadAccess = await scanner.hasDownloadsAccess();
      if (!hadAccess && !await _ensureDownloadsAccess(scanner)) return null;
      if (!mounted) return null;
      if (!hadAccess) {
        final additionalFolder = await widget.deviceCatalog.chooseFolder();
        if (additionalFolder != null && mounted) {
          widget.controller.addBookScanFolder(additionalFolder);
          await widget.controller.flush();
        }
      }
      downloads = await scanner.scanDownloads();
    } else if (widget.controller.appPreferences.bookScanFolders.isEmpty) {
      final folder = await widget.deviceCatalog.chooseFolder();
      if (folder == null || !mounted) return null;
      widget.controller.addBookScanFolder(folder);
      await widget.controller.flush();
    }

    final folders = widget.controller.appPreferences.bookScanFolders;
    final additional = folders.isEmpty
        ? const DeviceBookScanResult()
        : await widget.deviceCatalog.scan(folders);
    final books = <String, DeviceBookCandidate>{
      for (final book in downloads.books) book.uri: book,
      for (final book in additional.books) book.uri: book,
    };
    return DeviceBookScanResult(
      books: books.values.toList(growable: false),
      inaccessibleFolderUris: {
        ...downloads.inaccessibleFolderUris,
        ...additional.inaccessibleFolderUris,
      }.toList(growable: false),
    );
  }

  Future<bool> _ensureDownloadsAccess(
    BookDownloadsCatalogGateway scanner,
  ) async {
    if (await scanner.hasDownloadsAccess()) return true;
    if (!mounted) return false;
    final strings = AppStrings.of(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => BookLeatherDialog(
            title: Text(strings.scanBooks),
            content: Text(strings.downloadsAccessExplanation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.grantFileAccess),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return false;
    final granted = await scanner.requestDownloadsAccess();
    if (!mounted) return false;
    if (!granted) _showMessage(strings.fileAccessNotGranted);
    return granted;
  }

  Future<bool> _repairScanFolderAccess(Set<String> inaccessibleUris) async {
    final strings = AppStrings.of(context);
    final replace =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => BookLeatherDialog(
            title: Text(strings.scanBooks),
            content: Text(strings.scanFolderAccessLost),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(strings.selectScanFolder),
              ),
            ],
          ),
        ) ??
        false;
    if (!replace || !mounted) return false;

    final replacement = await widget.deviceCatalog.chooseFolder();
    if (replacement == null || !mounted) return false;
    final inaccessible = widget.controller.appPreferences.bookScanFolders
        .where((folder) => inaccessibleUris.contains(folder.uri))
        .toList();
    for (final folder in inaccessible) {
      await widget.deviceCatalog.releaseFolder(folder);
      widget.controller.removeBookScanFolder(folder.uri);
    }
    widget.controller.addBookScanFolder(replacement);
    await widget.controller.flush();
    return true;
  }

  void _showScanResult(BookImportBatchResult result) {
    final strings = AppStrings.of(context);
    final messages = <String>[
      if (result.imported.isNotEmpty)
        '${strings.bookImported}: ${result.imported.length}',
      if (result.duplicateCount > 0)
        '${strings.duplicateBooksSkipped}: ${result.duplicateCount}',
      if (result.failedCount > 0)
        '${strings.someBooksFailed}: ${result.failedCount}',
    ];
    _showMessage(messages.isEmpty ? strings.noNewBooks : messages.join(' · '));
  }

  Future<void> _openReader(BookProject project) async {
    widget.controller.selectProject(project.id);
    if (!mounted) return;
    final activeProject = widget.controller.activeProject;
    if (activeProject == null) return;
    var selected = activeProject;
    if (selected.isCatalogOnly) {
      _showImportProgress(message: AppStrings.of(context).openingBook);
      try {
        selected = await BookReadingSessionLoader(
          widget.sourceStorage,
        ).load(selected);
      } on Exception {
        if (mounted) {
          _hideImportProgress();
          _showMessage(AppStrings.of(context).bookImportFailed);
        }
        return;
      }
      if (!mounted) return;
      _hideImportProgress();
    }
    if (selected.sections.isEmpty) return;
    widget.controller.beginReaderSession(hydratedProject: selected);
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
    } on Object {
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
