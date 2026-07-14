import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/diary/application/diary_controller.dart';
import 'package:dnevnik/features/diary/presentation/book_entry_point.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

class DiaryApp extends StatelessWidget {
  const DiaryApp({required this.controller, super.key});

  final DiaryController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
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
        onGenerateTitle: (context) => AppStrings.of(context).appTitle,
        theme: AppTheme.dark,
        home: BookEntryPoint(controller: controller),
      ),
    );
  }
}
