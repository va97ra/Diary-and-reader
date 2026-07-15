import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_pdf_font_assets.dart';
import 'package:dnevnik/features/books/data/book_export_file_service.dart';
import 'package:dnevnik/features/books/data/book_pdf_asset_font_loader.dart';
import 'package:dnevnik/features/books/presentation/author_workspace_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

class AuthorStudioApp extends StatelessWidget {
  const AuthorStudioApp({
    required this.controller,
    this.exportFileSaver = const BookExportFileService(),
    this.pdfFontLoader = const BookPdfAssetFontLoader(),
    super.key,
  });

  final AuthorWorkspaceController controller;
  final BookExportFileSaver exportFileSaver;
  final BookPdfFontLoader pdfFontLoader;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
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
      theme: AppTheme.dark,
      home: AuthorWorkspacePage(
        controller: controller,
        exportFileSaver: exportFileSaver,
        pdfFontLoader: pdfFontLoader,
      ),
    ),
  );
}
