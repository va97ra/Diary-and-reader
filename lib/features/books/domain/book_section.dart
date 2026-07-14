import 'package:dnevnik/features/books/domain/rich_document.dart';

enum BookSectionType { part, chapter, scene }

enum DraftStatus { planned, draft, revision, complete }

class BookSection {
  const BookSection({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
  });

  factory BookSection.create({
    required String title,
    required BookSectionType type,
    String? parentId,
    String? id,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return BookSection(
      id: id ?? timestamp.microsecondsSinceEpoch.toString(),
      title: title,
      type: type,
      status: DraftStatus.draft,
      content: emptyRichDocument(),
      parentId: parentId,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  factory BookSection.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    return BookSection(
      id:
          json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      type: _enumValue(
        BookSectionType.values,
        json['type']?.toString(),
        BookSectionType.chapter,
      ),
      status: _enumValue(
        DraftStatus.values,
        json['status']?.toString(),
        DraftStatus.draft,
      ),
      content: richDocumentFromJson(json['content']),
      parentId: json['parentId']?.toString(),
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? createdAt,
    );
  }

  final String id;
  final String title;
  final BookSectionType type;
  final DraftStatus status;
  final RichDocument content;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookSection copyWith({
    String? title,
    BookSectionType? type,
    DraftStatus? status,
    RichDocument? content,
    String? parentId,
    bool clearParent = false,
    DateTime? updatedAt,
  }) => BookSection(
    id: id,
    title: title ?? this.title,
    type: type ?? this.type,
    status: status ?? this.status,
    content: content ?? this.content,
    parentId: clearParent ? null : parentId ?? this.parentId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'status': status.name,
    'content': content,
    'parentId': parentId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

T _enumValue<T extends Enum>(List<T> values, String? name, T fallback) =>
    values.where((value) => value.name == name).firstOrNull ?? fallback;
