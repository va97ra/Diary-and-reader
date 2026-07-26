import 'package:dnevnik/features/books/domain/book_section.dart';

class BookSectionTrashEntry {
  const BookSectionTrashEntry({
    required this.id,
    required this.deletedAt,
    required this.originalIndex,
    required this.sections,
  });

  factory BookSectionTrashEntry.fromJson(Map<String, dynamic> json) {
    final sections = (json['sections'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => BookSection.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return BookSectionTrashEntry(
      id:
          json['id']?.toString() ??
          'trash-${DateTime.now().microsecondsSinceEpoch}',
      deletedAt:
          DateTime.tryParse(json['deletedAt']?.toString() ?? '') ??
          DateTime.now(),
      originalIndex: (json['originalIndex'] is num
          ? (json['originalIndex'] as num).toInt()
          : 0),
      sections: sections,
    );
  }

  final String id;
  final DateTime deletedAt;
  final int originalIndex;
  final List<BookSection> sections;

  BookSection get root => sections.first;

  Map<String, Object> toJson() => {
    'id': id,
    'deletedAt': deletedAt.toIso8601String(),
    'originalIndex': originalIndex,
    'sections': sections.map((section) => section.toJson()).toList(),
  };
}
