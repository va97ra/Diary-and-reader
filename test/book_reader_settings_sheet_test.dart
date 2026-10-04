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

  testWidgets('text size and named choices apply and hide the sheet', (
    tester,
  ) async {
    final applied = <BookReaderSettings>[];
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: const Size(390, 844)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => BookReaderSettingsSheet(
                    settings: const BookReaderSettings(),
                    onChanged: applied.add,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    Future<void> open() async {
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    await open();
    expect(find.byType(Slider), findsNothing);
    // Any size is one choice away; the sheet then hides to show the book.
    await tester.tap(find.byKey(const ValueKey('reader-font-size')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24').last);
    await tester.pumpAndSettle();
    expect(applied.single.fontSize, 24);
    expect(find.byType(BookReaderSettingsSheet), findsNothing);

    // Margins are named, not given in pixels.
    await open();
    await tester.tap(find.byKey(const ValueKey('reader-side-margins')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Широкие').last);
    await tester.pumpAndSettle();
    expect(applied.last.horizontalPadding, 56);
    expect(find.byType(BookReaderSettingsSheet), findsNothing);

    // What the page does not show leaves the sheet open.
    await open();
    expect(find.textContaining('px'), findsNothing);
    // Text width means nothing on a phone, so it is not offered.
    expect(find.byKey(const ValueKey('reader-text-width')), findsNothing);
    final swipe = find.text('Свайп листает главы');
    await tester.ensureVisible(swipe);
    await tester.pumpAndSettle();
    await tester.tap(swipe);
    await tester.pumpAndSettle();
    expect(applied.last.swipeChapterNavigation, isFalse);
    expect(find.byType(BookReaderSettingsSheet), findsOneWidget);
  });
}

void _ignoreSettings(BookReaderSettings _) {}
