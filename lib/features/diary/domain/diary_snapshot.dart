import 'package:dnevnik/features/diary/domain/diary_entry.dart';
import 'package:dnevnik/features/diary/domain/page_margins.dart';

class DiarySnapshot {
  factory DiarySnapshot.fromJson(Map<String, dynamic> json) {
    final entries = (json['entries'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => DiaryEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return DiarySnapshot(
      entries: entries,
      activeEntryId: json['activeEntryId']?.toString(),
      languageCode: json['languageCode'] == 'en' ? 'en' : 'ru',
      margins: json['margins'] is Map
          ? PageMargins.fromJson(
              Map<String, dynamic>.from(json['margins'] as Map),
            )
          : const PageMargins.normal(),
    );
  }
  const DiarySnapshot({
    required this.entries,
    required this.activeEntryId,
    required this.languageCode,
    required this.margins,
  });

  final List<DiaryEntry> entries;
  final String? activeEntryId;
  final String languageCode;
  final PageMargins margins;

  Map<String, dynamic> toJson() => {
    'entries': entries.map((entry) => entry.toJson()).toList(),
    'activeEntryId': activeEntryId,
    'languageCode': languageCode,
    'margins': margins.toJson(),
  };
}
