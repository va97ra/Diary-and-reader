import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('spread choice is hidden on a portrait phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: const Size(390, 844)),
          child: child!,
        ),
        home: const Scaffold(
          body: BookReaderSettingsSheet(
            settings: BookReaderSettings(),
            onChanged: _ignoreSettings,
          ),
        ),
      ),
    );

    expect(find.text('Лента'), findsOneWidget);
    expect(find.text('Страница'), findsOneWidget);
    expect(find.text('Разворот'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('spread choice remains available on a wide screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 600));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: const Size(900, 600)),
          child: child!,
        ),
        home: const Scaffold(
          body: BookReaderSettingsSheet(
            settings: BookReaderSettings(),
            onChanged: _ignoreSettings,
          ),
        ),
      ),
    );

    expect(find.text('Разворот'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('font slider previews locally and commits once on release', (
    tester,
  ) async {
    final applied = <BookReaderSettings>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: BookReaderSettingsSheet(
            settings: const BookReaderSettings(),
            onChanged: applied.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final slider = find.byType(Slider).first;
    final gesture = await tester.startGesture(tester.getCenter(slider));
    await gesture.moveBy(const Offset(70, 0));
    await tester.pump();

    expect(applied, isEmpty);

    await gesture.up();
    await tester.pump();

    expect(applied, hasLength(1));
    expect(applied.single.fontSize, isNot(const BookReaderSettings().fontSize));
  });
}

void _ignoreSettings(BookReaderSettings _) {}
