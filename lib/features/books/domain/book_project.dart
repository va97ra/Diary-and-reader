import 'dart:collection';

import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_library_state.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_plain_text_chunk.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/book_section_trash.dart';
import 'package:dnevnik/features/books/domain/book_writing_state.dart';
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
    this.sourceStoredPath = '',
    this.sourceFingerprint = '',
    this.sourceExternalUri = '',
    this.sourceFileSize = 0,
    this.sourceModifiedMillis = 0,
    this.catalogReadingProgress = 0,
    this.collectionName = '',
    this.libraryState = const BookLibraryState(),
    this.writingState = const BookWritingState(),
    List<BookSectionTrashEntry> sectionTrash = const [],
    List<BookAsset> assets = const [],
    this.coverAssetId,
    BookReaderAnnotations? readerAnnotations,
  }) : readerAnnotations = readerAnnotations ?? BookReaderAnnotations(),
       _sections = List.unmodifiable(sections),
       _sectionTrash = List.unmodifiable(sectionTrash),
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
    final kind =
        BookProjectKind.values.where((kind) {
          return kind.name == json['kind']?.toString();
        }).firstOrNull ??
        BookProjectKind.manuscript;
    final sourceFormat = json['sourceFormat']?.toString() ?? '';
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
    final sectionMigration = _migrateOversizedPlainTextSections(
      sections,
      kind: kind,
      sourceFormat: sourceFormat,
    );
    sections = sectionMigration.sections;
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final requestedActiveId = json['activeSectionId']?.toString();
    final sectionIds = sections.map((section) => section.id).toSet();
    final storedReaderProgress = json['readerProgress'] is Map
        ? BookReaderProgress.fromJson(
            Map<String, dynamic>.from(json['readerProgress'] as Map),
          )
        : BookReaderProgress(sectionId: sections.firstOrNull?.id);
    final requestedReaderProgress = sectionMigration.remapProgress(
      storedReaderProgress,
    );
    final isImportedCatalog =
        kind == BookProjectKind.importedBook && sections.isEmpty;
    final readerProgress = isImportedCatalog
        ? requestedReaderProgress
        : sectionIds.contains(requestedReaderProgress.sectionId)
        ? requestedReaderProgress
        : BookReaderProgress(sectionId: sections.firstOrNull?.id);
    final storedReaderAnnotations = (json['readerAnnotations'] is Map
        ? BookReaderAnnotations.fromJson(
            Map<String, dynamic>.from(json['readerAnnotations'] as Map),
          )
        : BookReaderAnnotations());
    final remappedAnnotations = sectionMigration.remapAnnotations(
      storedReaderAnnotations,
    );
    final readerAnnotations = isImportedCatalog
        ? remappedAnnotations
        : remappedAnnotations.retainSections(sectionIds);
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
      kind: kind,
      sourceFormat: sourceFormat,
      sourceFileName: json['sourceFileName']?.toString() ?? '',
      sourceStoredPath: json['sourceStoredPath']?.toString() ?? '',
      sourceFingerprint: json['sourceFingerprint']?.toString() ?? '',
      sourceExternalUri: json['sourceExternalUri']?.toString() ?? '',
      sourceFileSize: json['sourceFileSize'] is num
          ? (json['sourceFileSize'] as num).toInt().clamp(0, 1 << 62).toInt()
          : 0,
      sourceModifiedMillis: json['sourceModifiedMillis'] is num
          ? (json['sourceModifiedMillis'] as num)
                .toInt()
                .clamp(0, 1 << 62)
                .toInt()
          : 0,
      catalogReadingProgress: _normalizedProgress(
        json['catalogReadingProgress'],
      ),
      collectionName: json['collectionName']?.toString() ?? '',
      libraryState: json['libraryState'] is Map
          ? BookLibraryState.fromJson(
              Map<String, dynamic>.from(json['libraryState'] as Map),
            )
          : const BookLibraryState(),
      writingState: json['writingState'] is Map
          ? BookWritingState.fromJson(
              Map<String, dynamic>.from(json['writingState'] as Map),
            )
          : const BookWritingState(),
      sectionTrash: (json['sectionTrash'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                BookSectionTrashEntry.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((entry) => entry.sections.isNotEmpty)
          .toList(),
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
  final String sourceStoredPath;
  final String sourceFingerprint;
  final String sourceExternalUri;
  final int sourceFileSize;
  final int sourceModifiedMillis;
  final double catalogReadingProgress;
  final String collectionName;
  final BookLibraryState libraryState;
  final BookWritingState writingState;
  final List<BookSectionTrashEntry> _sectionTrash;
  final List<BookAsset> _assets;
  final String? coverAssetId;

  bool get isReadOnly => kind == BookProjectKind.importedBook;
  bool get isCatalogOnly => isReadOnly && _sections.isEmpty;

  UnmodifiableListView<BookSection> get sections =>
      UnmodifiableListView(_sections);

  UnmodifiableListView<BookAsset> get assets => UnmodifiableListView(_assets);

  UnmodifiableListView<BookSectionTrashEntry> get sectionTrash =>
      UnmodifiableListView(_sectionTrash);

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
    String? sourceStoredPath,
    String? sourceFingerprint,
    String? sourceExternalUri,
    int? sourceFileSize,
    int? sourceModifiedMillis,
    double? catalogReadingProgress,
    bool clearStoredSource = false,
    String? collectionName,
    BookLibraryState? libraryState,
    BookWritingState? writingState,
    List<BookSectionTrashEntry>? sectionTrash,
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
    sourceStoredPath: clearStoredSource
        ? ''
        : sourceStoredPath ?? this.sourceStoredPath,
    sourceFingerprint: sourceFingerprint ?? this.sourceFingerprint,
    sourceExternalUri: sourceExternalUri ?? this.sourceExternalUri,
    sourceFileSize: clearStoredSource
        ? 0
        : sourceFileSize ?? this.sourceFileSize,
    sourceModifiedMillis: sourceModifiedMillis ?? this.sourceModifiedMillis,
    catalogReadingProgress: _normalizedProgress(
      catalogReadingProgress ?? this.catalogReadingProgress,
    ),
    collectionName: collectionName ?? this.collectionName,
    libraryState: libraryState ?? this.libraryState,
    writingState: writingState ?? this.writingState,
    sectionTrash: sectionTrash ?? _sectionTrash,
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
    'sourceStoredPath': sourceStoredPath,
    'sourceFingerprint': sourceFingerprint,
    'sourceExternalUri': sourceExternalUri,
    'sourceFileSize': sourceFileSize,
    'sourceModifiedMillis': sourceModifiedMillis,
    'catalogReadingProgress': catalogReadingProgress,
    'collectionName': collectionName,
    'libraryState': libraryState.toJson(),
    'writingState': writingState.toJson(),
    'sectionTrash': _sectionTrash.map((entry) => entry.toJson()).toList(),
    'assets': _assets.map((asset) => asset.toJson()).toList(),
    'coverAssetId': coverAssetId,
    'documentFormatVersion': _currentDocumentFormatVersion,
  };
}

const _currentDocumentFormatVersion = 3;
const _automaticLineHeightMigrationVersion = 2;

double _normalizedProgress(Object? value) {
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  if (parsed == null || !parsed.isFinite) return 0;
  return parsed.clamp(0, 1).toDouble();
}

_PlainTextSectionMigration _migrateOversizedPlainTextSections(
  List<BookSection> sections, {
  required BookProjectKind kind,
  required String sourceFormat,
}) {
  if (kind != BookProjectKind.importedBook ||
      !_plainTextSourceFormats.contains(sourceFormat.toUpperCase())) {
    return _PlainTextSectionMigration.unchanged(sections);
  }

  final migrated = <BookSection>[];
  final ranges = <String, List<_PlainTextChunkRange>>{};
  for (final section in sections) {
    final text = richDocumentPlainText(section.content);
    final isPlainText = section.content.every(
      (operation) => operation['insert'] is String,
    );
    if (!isPlainText || text.length <= BookPlainTextChunker.maximumCharacters) {
      migrated.add(section);
      continue;
    }

    final chunks = BookPlainTextChunker.split(text);
    final chunkRanges = <_PlainTextChunkRange>[];
    for (var index = 0; index < chunks.length; index++) {
      final chunk = chunks[index];
      final id = index == 0 ? section.id : '${section.id}-part-${index + 1}';
      migrated.add(
        BookSection(
          id: id,
          title:
              chunk.heading ??
              (index == 0 ? section.title : '${section.title} — ${index + 1}'),
          type: section.type,
          status: section.status,
          content: [
            {
              'insert': chunk.text.endsWith('\n')
                  ? chunk.text
                  : '${chunk.text}\n',
            },
          ],
          createdAt: section.createdAt,
          updatedAt: section.updatedAt,
          parentId: section.parentId,
          targetWords: section.targetWords,
        ),
      );
      chunkRanges.add(
        _PlainTextChunkRange(
          sectionId: id,
          startOffset: chunk.startOffset,
          endOffset: chunk.endOffset,
        ),
      );
    }
    ranges[section.id] = chunkRanges;
  }
  return _PlainTextSectionMigration(migrated, ranges);
}

const _plainTextSourceFormats = {'TXT', 'RTF', 'DOCX'};

class _PlainTextChunkRange {
  const _PlainTextChunkRange({
    required this.sectionId,
    required this.startOffset,
    required this.endOffset,
  });

  final String sectionId;
  final int startOffset;
  final int endOffset;

  int get length => endOffset - startOffset;
}

class _PlainTextSectionMigration {
  const _PlainTextSectionMigration(this.sections, this._ranges);

  factory _PlainTextSectionMigration.unchanged(List<BookSection> sections) =>
      _PlainTextSectionMigration(sections, const {});

  final List<BookSection> sections;
  final Map<String, List<_PlainTextChunkRange>> _ranges;

  BookReaderProgress remapProgress(BookReaderProgress progress) {
    final point = _point(progress.sectionId, progress.sectionProgress);
    if (point == null) return progress;
    return BookReaderProgress(
      sectionId: point.range.sectionId,
      sectionProgress: point.localProgress,
    );
  }

  BookReaderAnnotations remapAnnotations(BookReaderAnnotations annotations) =>
      BookReaderAnnotations(
        bookmarks: annotations.bookmarks.map((bookmark) {
          final point = _point(bookmark.sectionId, bookmark.sectionProgress);
          if (point == null) return bookmark;
          return BookReaderBookmark(
            id: bookmark.id,
            sectionId: point.range.sectionId,
            sectionProgress: point.localProgress,
            excerpt: bookmark.excerpt,
            createdAt: bookmark.createdAt,
          );
        }).toList(),
        notes: annotations.notes.map((note) {
          final point = _point(note.sectionId, note.sectionProgress);
          if (point == null) return note;
          return BookReaderNote(
            id: note.id,
            sectionId: point.range.sectionId,
            sectionProgress: point.localProgress,
            excerpt: note.excerpt,
            text: note.text,
            createdAt: note.createdAt,
            updatedAt: note.updatedAt,
          );
        }).toList(),
        highlights: annotations.highlights.map((highlight) {
          final range = _range(
            highlight.sectionId,
            highlight.startOffset,
            highlight.endOffset,
          );
          if (range == null) return highlight;
          return BookReaderHighlight(
            id: highlight.id,
            sectionId: range.chunk.sectionId,
            sectionProgress: range.sectionProgress,
            startOffset: range.startOffset,
            endOffset: range.endOffset,
            excerpt: highlight.excerpt,
            color: highlight.color,
            createdAt: highlight.createdAt,
          );
        }).toList(),
        quotes: annotations.quotes.map((quote) {
          final range = _range(
            quote.sectionId,
            quote.startOffset,
            quote.endOffset,
          );
          if (range == null) return quote;
          return BookReaderQuote(
            id: quote.id,
            sectionId: range.chunk.sectionId,
            sectionProgress: range.sectionProgress,
            startOffset: range.startOffset,
            endOffset: range.endOffset,
            text: quote.text,
            createdAt: quote.createdAt,
          );
        }).toList(),
      );

  _RemappedPoint? _point(String? sectionId, double progress) {
    final chunks = _ranges[sectionId];
    if (chunks == null || chunks.isEmpty) return null;
    final totalLength = chunks.last.endOffset;
    final absoluteOffset = (totalLength * progress.clamp(0, 1)).round();
    final chunk = chunks.firstWhere(
      (item) => absoluteOffset < item.endOffset,
      orElse: () => chunks.last,
    );
    final localOffset = (absoluteOffset - chunk.startOffset).clamp(
      0,
      chunk.length,
    );
    return _RemappedPoint(
      chunk,
      chunk.length == 0 ? 0 : localOffset / chunk.length,
    );
  }

  _RemappedRange? _range(String sectionId, int start, int end) {
    final chunks = _ranges[sectionId];
    if (chunks == null || chunks.isEmpty) return null;
    final normalizedStart = start.clamp(0, chunks.last.endOffset);
    final normalizedEnd = end.clamp(normalizedStart, chunks.last.endOffset);
    final chunk = chunks.firstWhere(
      (item) => normalizedStart < item.endOffset,
      orElse: () => chunks.last,
    );
    final localStart = (normalizedStart - chunk.startOffset).clamp(
      0,
      chunk.length,
    );
    final localEnd = (normalizedEnd - chunk.startOffset).clamp(
      localStart,
      chunk.length,
    );
    return _RemappedRange(
      chunk: chunk,
      startOffset: localStart,
      endOffset: localEnd,
      sectionProgress: chunk.length == 0 ? 0 : localStart / chunk.length,
    );
  }
}

class _RemappedPoint {
  const _RemappedPoint(this.range, this.localProgress);

  final _PlainTextChunkRange range;
  final double localProgress;
}

class _RemappedRange {
  const _RemappedRange({
    required this.chunk,
    required this.startOffset,
    required this.endOffset,
    required this.sectionProgress,
  });

  final _PlainTextChunkRange chunk;
  final int startOffset;
  final int endOffset;
  final double sectionProgress;
}
