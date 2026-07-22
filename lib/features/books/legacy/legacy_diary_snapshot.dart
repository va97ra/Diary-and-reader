typedef LegacyPageDocument = List<Map<String, dynamic>>;

class LegacyDiaryEntry {
  const LegacyDiaryEntry({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.pages,
  });

  factory LegacyDiaryEntry.fromJson(Map<String, dynamic> json) {
    final rawPages = json['pages'];
    final pages = rawPages is List
        ? rawPages.map<LegacyPageDocument>(_pageFromJson).toList()
        : <LegacyPageDocument>[_emptyPage()];
    return LegacyDiaryEntry(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      pages: pages.isEmpty ? [_emptyPage()] : pages,
    );
  }

  final String id;
  final String title;
  final DateTime createdAt;
  final List<LegacyPageDocument> pages;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'pages': pages,
  };

  static LegacyPageDocument _emptyPage() => [
    <String, dynamic>{'insert': '\n'},
  ];

  static LegacyPageDocument _pageFromJson(Object? value) {
    if (value is! List) return _emptyPage();
    final operations = value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return operations.isEmpty ? _emptyPage() : operations;
  }
}

class LegacyDiarySnapshot {
  const LegacyDiarySnapshot({
    required this.entries,
    required this.activeEntryId,
    required this.languageCode,
  });

  factory LegacyDiarySnapshot.fromJson(Map<String, dynamic> json) {
    final entries = (json['entries'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) => LegacyDiaryEntry.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    return LegacyDiarySnapshot(
      entries: entries,
      activeEntryId: json['activeEntryId']?.toString(),
      languageCode: json['languageCode'] == 'en' ? 'en' : 'ru',
    );
  }

  final List<LegacyDiaryEntry> entries;
  final String? activeEntryId;
  final String languageCode;

  Map<String, dynamic> toJson() => {
    'entries': entries.map((entry) => entry.toJson()).toList(),
    'activeEntryId': activeEntryId,
    'languageCode': languageCode,
  };
}
