import 'dart:collection';

import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';

enum BookProjectKind { manuscript, importedBook }

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
    this.readerSettings = const BookReaderSettings(),
    this.readerProgress = const BookReaderProgress(),
    this.kind = BookProjectKind.manuscript,
    this.sourceFormat = '',
    this.sourceFileName = '',
    List<BookAsset> assets = const [],
    this.coverAssetId,
    BookReaderAnnotations? readerAnnotations,
  }) : readerAnnotations = readerAnnotations ?? BookReaderAnnotations(),
       _sections = List.unmodifiable(sections),
       _assets = List.unmodifiable(assets);

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
      readerSettings: const BookReaderSettings(),
      readerProgress: BookReaderProgress(sectionId: chapter.id),
      readerAnnotations: BookReaderAnnotations(),
      kind: BookProjectKind.manuscript,
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
    if (documentFormatVersion < _automaticLineHeightMigrationVersion) {
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
    final sectionIds = sections.map((section) => section.id).toSet();
    final requestedReaderProgress = json['readerProgress'] is Map
        ? BookReaderProgress.fromJson(
            Map<String, dynamic>.from(json['readerProgress'] as Map),
          )
        : BookReaderProgress(sectionId: sections.firstOrNull?.id);
    final readerProgress =
        sectionIds.contains(requestedReaderProgress.sectionId)
        ? requestedReaderProgress
        : BookReaderProgress(sectionId: sections.firstOrNull?.id);
    final readerAnnotations =
        (json['readerAnnotations'] is Map
                ? BookReaderAnnotations.fromJson(
                    Map<String, dynamic>.from(json['readerAnnotations'] as Map),
                  )
                : BookReaderAnnotations())
            .retainSections(sectionIds);
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
      readerSettings: json['readerSettings'] is Map
          ? BookReaderSettings.fromJson(
              Map<String, dynamic>.from(json['readerSettings'] as Map),
            )
          : const BookReaderSettings(),
      readerProgress: readerProgress,
      readerAnnotations: readerAnnotations,
      kind:
          BookProjectKind.values.where((kind) {
            return kind.name == json['kind']?.toString();
          }).firstOrNull ??
          BookProjectKind.manuscript,
      sourceFormat: json['sourceFormat']?.toString() ?? '',
      sourceFileName: json['sourceFileName']?.toString() ?? '',
      assets: (json['assets'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (asset) => BookAsset.tryFromJson(Map<String, dynamic>.from(asset)),
          )
          .whereType<BookAsset>()
          .where((asset) => asset.id.isNotEmpty && asset.isRenderableImage)
          .toList(),
      coverAssetId: json['coverAssetId']?.toString(),
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
  final BookReaderSettings readerSettings;
  final BookReaderProgress readerProgress;
  final BookReaderAnnotations readerAnnotations;
  final BookProjectKind kind;
  final String sourceFormat;
  final String sourceFileName;
  final List<BookAsset> _assets;
  final String? coverAssetId;

  bool get isReadOnly => kind == BookProjectKind.importedBook;

  UnmodifiableListView<BookSection> get sections =>
      UnmodifiableListView(_sections);

  UnmodifiableListView<BookAsset> get assets => UnmodifiableListView(_assets);

  BookAsset? get coverAsset => _assets
      .where((asset) => asset.id == coverAssetId && asset.isRenderableImage)
      .firstOrNull;

  BookAsset? assetById(String id) =>
      _assets.where((asset) => asset.id == id).firstOrNull;

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
    BookReaderSettings? readerSettings,
    BookReaderProgress? readerProgress,
    BookReaderAnnotations? readerAnnotations,
    BookProjectKind? kind,
    String? sourceFormat,
    String? sourceFileName,
    List<BookAsset>? assets,
    String? coverAssetId,
    bool clearCoverAsset = false,
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
    readerSettings: readerSettings ?? this.readerSettings,
    readerProgress: readerProgress ?? this.readerProgress,
    readerAnnotations: readerAnnotations ?? this.readerAnnotations,
    kind: kind ?? this.kind,
    sourceFormat: sourceFormat ?? this.sourceFormat,
    sourceFileName: sourceFileName ?? this.sourceFileName,
    assets: assets ?? _assets,
    coverAssetId: clearCoverAsset ? null : coverAssetId ?? this.coverAssetId,
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
    'readerSettings': readerSettings.toJson(),
    'readerProgress': readerProgress.toJson(),
    'readerAnnotations': readerAnnotations.toJson(),
    'kind': kind.name,
    'sourceFormat': sourceFormat,
    'sourceFileName': sourceFileName,
    'assets': _assets.map((asset) => asset.toJson()).toList(),
    'coverAssetId': coverAssetId,
    'documentFormatVersion': _currentDocumentFormatVersion,
  };
}

const _currentDocumentFormatVersion = 3;
const _automaticLineHeightMigrationVersion = 2;
