import 'dart:collection';

import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';

class BookProject {
  BookProject({
    required this.id,
    required this.metadata,
    required List<BookSection> sections,
    required this.activeSectionId,
    required this.createdAt,
    required this.updatedAt,
    this.layoutSettings = const BookLayoutSettings(),
    this.paragraphSettings = const BookParagraphSettings(),
  }) : _sections = List.unmodifiable(sections);

  factory BookProject.create({
    required String title,
    required String chapterTitle,
    String languageCode = 'ru',
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final projectId = 'book-${timestamp.microsecondsSinceEpoch}';
    final chapter = BookSection.create(
      id: '$projectId-chapter-1',
      title: chapterTitle,
      type: BookSectionType.chapter,
      now: timestamp,
    );
    return BookProject(
      id: projectId,
      metadata: BookMetadata(title: title, languageCode: languageCode),
      sections: [chapter],
      activeSectionId: chapter.id,
      createdAt: timestamp,
      updatedAt: timestamp,
      layoutSettings: const BookLayoutSettings(),
      paragraphSettings: BookParagraphSettings.forPreset(
        BookParagraphPreset.modern,
      ),
    );
  }

  factory BookProject.fromJson(Map<String, dynamic> json) {
    var sections = (json['sections'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (section) => BookSection.fromJson(Map<String, dynamic>.from(section)),
        )
        .toList();
    final documentFormatVersion = json['documentFormatVersion'] is num
        ? (json['documentFormatVersion'] as num).toInt()
        : 1;
    if (documentFormatVersion < _currentDocumentFormatVersion) {
      sections = sections
          .map(
            (section) => section.copyWith(
              content: withoutLegacyDefaultLineHeight(section.content),
            ),
          )
          .toList();
    }
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final requestedActiveId = json['activeSectionId']?.toString();
    return BookProject(
      id:
          json['id']?.toString() ??
          'book-${DateTime.now().microsecondsSinceEpoch}',
      metadata: json['metadata'] is Map
          ? BookMetadata.fromJson(
              Map<String, dynamic>.from(json['metadata'] as Map),
            )
          : const BookMetadata(title: ''),
      sections: sections,
      activeSectionId:
          sections.any((section) => section.id == requestedActiveId)
          ? requestedActiveId
          : sections.firstOrNull?.id,
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? createdAt,
      layoutSettings: json['layoutSettings'] is Map
          ? BookLayoutSettings.fromJson(
              Map<String, dynamic>.from(json['layoutSettings'] as Map),
            )
          : const BookLayoutSettings(),
      paragraphSettings: json['paragraphSettings'] is Map
          ? BookParagraphSettings.fromJson(
              Map<String, dynamic>.from(json['paragraphSettings'] as Map),
            )
          : const BookParagraphSettings(),
    );
  }

  final String id;
  final BookMetadata metadata;
  final List<BookSection> _sections;
  final String? activeSectionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final BookLayoutSettings layoutSettings;
  final BookParagraphSettings paragraphSettings;

  UnmodifiableListView<BookSection> get sections =>
      UnmodifiableListView(_sections);

  BookSection? get activeSection =>
      _sections.where((section) => section.id == activeSectionId).firstOrNull;

  Iterable<BookSection> childrenOf(String? parentId) =>
      _sections.where((section) => section.parentId == parentId);

  BookProject copyWith({
    BookMetadata? metadata,
    List<BookSection>? sections,
    String? activeSectionId,
    bool clearActiveSection = false,
    DateTime? updatedAt,
    BookLayoutSettings? layoutSettings,
    BookParagraphSettings? paragraphSettings,
  }) => BookProject(
    id: id,
    metadata: metadata ?? this.metadata,
    sections: sections ?? _sections,
    activeSectionId: clearActiveSection
        ? null
        : activeSectionId ?? this.activeSectionId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    layoutSettings: layoutSettings ?? this.layoutSettings,
    paragraphSettings: paragraphSettings ?? this.paragraphSettings,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'metadata': metadata.toJson(),
    'sections': _sections.map((section) => section.toJson()).toList(),
    'activeSectionId': activeSectionId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'layoutSettings': layoutSettings.toJson(),
    'paragraphSettings': paragraphSettings.toJson(),
    'documentFormatVersion': _currentDocumentFormatVersion,
  };
}

const _currentDocumentFormatVersion = 2;
