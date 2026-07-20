import 'dart:collection';

import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_scan_folder.dart';

enum LiteriaThemePreference { system, light, dark }

class LiteriaAppPreferences {
  const LiteriaAppPreferences({
    this.theme = LiteriaThemePreference.system,
    this.readerSettings = const BookReaderSettings(),
    this.lastManuscriptId,
    this.lastReadingId,
    this.onboardingSeen = false,
    List<BookScanFolder> bookScanFolders = const [],
    // The getter below exposes this owned list as an unmodifiable view.
    // ignore: prefer_initializing_formals
  }) : _bookScanFolders = bookScanFolders;

  factory LiteriaAppPreferences.fromJson(Map<String, dynamic> json) =>
      LiteriaAppPreferences(
        theme:
            LiteriaThemePreference.values
                .where((value) => value.name == json['theme']?.toString())
                .firstOrNull ??
            LiteriaThemePreference.system,
        readerSettings: json['readerSettings'] is Map
            ? BookReaderSettings.fromJson(
                Map<String, dynamic>.from(json['readerSettings'] as Map),
              )
            : const BookReaderSettings(),
        lastManuscriptId: json['lastManuscriptId']?.toString(),
        lastReadingId: json['lastReadingId']?.toString(),
        onboardingSeen: json['onboardingSeen'] == true,
        bookScanFolders: (json['bookScanFolders'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (folder) =>
                  BookScanFolder.fromJson(Map<String, dynamic>.from(folder)),
            )
            .where((folder) => folder.uri.isNotEmpty)
            .toList(),
      );

  final LiteriaThemePreference theme;
  final BookReaderSettings readerSettings;
  final String? lastManuscriptId;
  final String? lastReadingId;
  final bool onboardingSeen;
  final List<BookScanFolder> _bookScanFolders;

  UnmodifiableListView<BookScanFolder> get bookScanFolders =>
      UnmodifiableListView(_bookScanFolders);

  LiteriaAppPreferences copyWith({
    LiteriaThemePreference? theme,
    BookReaderSettings? readerSettings,
    String? lastManuscriptId,
    String? lastReadingId,
    bool? onboardingSeen,
    List<BookScanFolder>? bookScanFolders,
    bool clearLastManuscript = false,
    bool clearLastReading = false,
  }) => LiteriaAppPreferences(
    theme: theme ?? this.theme,
    readerSettings: readerSettings ?? this.readerSettings,
    lastManuscriptId: clearLastManuscript
        ? null
        : lastManuscriptId ?? this.lastManuscriptId,
    lastReadingId: clearLastReading
        ? null
        : lastReadingId ?? this.lastReadingId,
    onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    bookScanFolders: bookScanFolders ?? this.bookScanFolders,
  );

  Map<String, dynamic> toJson() => {
    'theme': theme.name,
    'readerSettings': readerSettings.toJson(),
    'lastManuscriptId': lastManuscriptId,
    'lastReadingId': lastReadingId,
    'onboardingSeen': onboardingSeen,
    'bookScanFolders': bookScanFolders
        .map((folder) => folder.toJson())
        .toList(),
  };
}
