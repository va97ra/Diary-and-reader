import 'dart:async';

import 'package:dnevnik/app/literia_home_shell.dart';
import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_device_catalog.dart';
import 'package:dnevnik/features/books/application/book_image_file.dart';
import 'package:dnevnik/features/books/application/book_pdf_font_assets.dart';
import 'package:dnevnik/features/books/application/book_source_storage.dart';
import 'package:dnevnik/features/books/data/book_export_file_service.dart';
import 'package:dnevnik/features/books/data/book_image_file_service.dart';
import 'package:dnevnik/features/books/data/book_import_file_service.dart';
import 'package:dnevnik/features/books/data/book_pdf_asset_font_loader.dart';
import 'package:dnevnik/features/books/data/book_project_backup_file_service.dart';
import 'package:dnevnik/features/books/domain/literia_app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

class AuthorStudioApp extends StatelessWidget {
  const AuthorStudioApp({
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
  Widget build(BuildContext context) => _WorkspaceSaveLifecycle(
    controller: controller,
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: Locale(controller.languageCode),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        onGenerateTitle: (context) => AppStrings.of(context).studioTitle,
        themeMode: switch (controller.themePreference) {
          LiteriaThemePreference.system => ThemeMode.system,
          LiteriaThemePreference.light => ThemeMode.light,
          LiteriaThemePreference.dark => ThemeMode.dark,
        },
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: LiteriaHomeShell(
          controller: controller,
          exportFileSaver: exportFileSaver,
          backupFileGateway: backupFileGateway,
          pdfFontLoader: pdfFontLoader,
          importFileGateway: importFileGateway,
          imageFileGateway: imageFileGateway,
          sourceStorage: sourceStorage,
          deviceCatalog: deviceCatalog,
        ),
      ),
    ),
  );
}

class _WorkspaceSaveLifecycle extends StatefulWidget {
  const _WorkspaceSaveLifecycle({
    required this.controller,
    required this.child,
  });

  final AuthorWorkspaceController controller;
  final Widget child;

  @override
  State<_WorkspaceSaveLifecycle> createState() =>
      _WorkspaceSaveLifecycleState();
}

class _WorkspaceSaveLifecycleState extends State<_WorkspaceSaveLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant _WorkspaceSaveLifecycle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      unawaited(oldWidget.controller.flush());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state
        case AppLifecycleState.inactive ||
            AppLifecycleState.hidden ||
            AppLifecycleState.paused ||
            AppLifecycleState.detached) {
      unawaited(widget.controller.flush());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.controller.flush());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
