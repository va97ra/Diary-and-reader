import 'dart:io';

import 'package:dnevnik/app/literia_settings_page.dart';
import 'package:dnevnik/app/literia_version.dart';
import 'package:dnevnik/features/books/domain/literia_app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpSettings(WidgetTester tester) => tester.pumpWidget(
  MaterialApp(
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: LiteriaSettingsPage(
      themePreference: LiteriaThemePreference.system,
      languageCode: 'ru',
      canBackup: true,
      onThemeChanged: (_) {},
      onLanguageChanged: (_) {},
      onBackup: () async {},
      onRestore: () async {},
      onOpenBookStorage: () {},
    ),
  ),
);

void main() {
  test('the shown version is the one in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([0-9.]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(literiaVersion, version);
  });

  testWidgets('theme and language share a line and the guide stays folded', (
    tester,
  ) async {
    await _pumpSettings(tester);

    expect(find.text('Литерия $literiaVersion'), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(const ValueKey('app-theme'))).dy,
      tester.getCenter(find.byKey(const ValueKey('app-language'))).dy,
    );
    expect(find.textContaining('«Писать»'), findsNothing);

    await tester.tap(find.text('Короткая инструкция'));
    await tester.pumpAndSettle();
    expect(find.textContaining('«Писать»'), findsOneWidget);
  });
}
