typedef PageDocument = List<Map<String, dynamic>>;

class DiaryEntry {
  factory DiaryEntry.create({required String title}) => DiaryEntry(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    title: title,
    createdAt: DateTime.now(),
    pages: [emptyPage()],
  );

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    final rawPages = json['pages'];
    final pages = rawPages is List
        ? rawPages.map<PageDocument>(_pageFromJson).toList()
        : <PageDocument>[emptyPage()];
    return DiaryEntry(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      pages: pages.isEmpty ? [emptyPage()] : pages,
    );
  }
  DiaryEntry({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.pages,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final List<PageDocument> pages;

  DiaryEntry copyWith({String? title, List<PageDocument>? pages}) => DiaryEntry(
    id: id,
    title: title ?? this.title,
    createdAt: createdAt,
    pages: pages ?? this.pages,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'pages': pages,
  };

  static PageDocument emptyPage() => [
    <String, dynamic>{'insert': '\n'},
  ];

  static PageDocument _pageFromJson(Object? value) {
    if (value is! List) return emptyPage();
    final operations = value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return operations.isEmpty ? emptyPage() : operations;
  }
}
