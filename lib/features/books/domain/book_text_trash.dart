import 'package:dnevnik/features/books/domain/rich_document.dart';

/// Text or pictures deleted from a chapter, kept so they can be put back.
class BookTextTrashEntry {
  const BookTextTrashEntry({
    required this.id,
    required this.deletedAt,
    required this.sectionId,
    required this.offset,
    required this.content,
  });

  factory BookTextTrashEntry.fromJson(Map<String, dynamic> json) =>
      BookTextTrashEntry(
        id:
            json['id']?.toString() ??
            'text-trash-${DateTime.now().microsecondsSinceEpoch}',
        deletedAt:
            DateTime.tryParse(json['deletedAt']?.toString() ?? '') ??
            DateTime.now(),
        sectionId: json['sectionId']?.toString() ?? '',
        offset: json['offset'] is num ? (json['offset'] as num).toInt() : 0,
        content: [
          for (final operation in json['content'] as List? ?? const [])
            if (operation is Map) Map<String, dynamic>.from(operation),
        ],
      );

  final String id;
  final DateTime deletedAt;
  final String sectionId;

  /// Where the fragment began in its chapter.
  final int offset;

  /// The fragment as document operations, formatting and pictures included.
  final RichDocument content;

  /// Whether the fragment holds a picture or another embedded object.
  bool get hasEmbed => content.any((operation) => operation['insert'] is Map);

  Map<String, Object> toJson() => {
    'id': id,
    'deletedAt': deletedAt.toIso8601String(),
    'sectionId': sectionId,
    'offset': offset,
    'content': content,
  };
}
