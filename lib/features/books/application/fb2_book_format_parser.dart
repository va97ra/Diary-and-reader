import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_format_parser.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_import_parsing_support.dart';
import 'package:dnevnik/features/books/application/xml_book_content_converter.dart';
import 'package:dnevnik/features/books/application/xml_text_decoder.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:xml/xml.dart';

class Fb2BookFormatParser implements BookFormatParser {
  const Fb2BookFormatParser();

  @override
  Set<BookImportFormat> get formats => const {
    BookImportFormat.fb2,
    BookImportFormat.fb2Zip,
  };

  @override
  BookProject parse(
    BookImportFile file,
    DateTime timestamp,
    BookImportFormat format,
  ) {
    if (format == BookImportFormat.fb2Zip) {
      return _parseArchive(file, timestamp);
    }
    return _parseSource(
      XmlTextDecoder.decode(file.bytes),
      file,
      timestamp,
      sourceFormat: 'FB2',
    );
  }

  BookProject parseCatalog(
    BookImportFile file,
    DateTime timestamp,
    BookImportFormat format,
  ) {
    final source = switch (format) {
      BookImportFormat.fb2 => XmlTextDecoder.decode(file.bytes),
      BookImportFormat.fb2Zip => _catalogArchiveSource(file),
      _ => throw const BookImportException(BookImportFailure.unsupportedFormat),
    };
    final document = XmlDocument.parse(
      XmlTextDecoder.normalizeEntities(source),
    );
    if (document.rootElement.name.local != 'FictionBook') {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    final titleInfo = BookImportParsingSupport.firstElement(
      document.rootElement,
      'title-info',
    );
    final title = BookImportParsingSupport.textOf(
      titleInfo,
      'book-title',
    ).ifEmpty(BookImportParsingSupport.baseName(file.name));
    final cover = _readCatalogCover(document, titleInfo);
    return BookImportParsingSupport.catalogProject(
      file: file,
      timestamp: timestamp,
      sourceFormat: format == BookImportFormat.fb2Zip ? 'FB2.ZIP' : 'FB2',
      metadata: BookMetadata(
        title: title,
        author: _author(
          BookImportParsingSupport.directElement(titleInfo, 'author'),
        ),
        description: BookImportParsingSupport.textOf(titleInfo, 'annotation'),
        languageCode: BookImportParsingSupport.language(
          BookImportParsingSupport.textOf(titleInfo, 'lang'),
        ),
        genre: BookImportParsingSupport.textOf(titleInfo, 'genre'),
        series:
            BookImportParsingSupport.directElement(
              titleInfo,
              'sequence',
            )?.getAttribute('name') ??
            '',
      ),
      assets: cover.assets,
      coverAssetId: cover.coverAssetId,
    );
  }

  String _catalogArchiveSource(BookImportFile file) {
    final archive = ZipDecoder().decodeBytes(file.bytes);
    final entry = archive.files.where((candidate) {
      return candidate.isFile && candidate.name.toLowerCase().endsWith('.fb2');
    }).firstOrNull;
    if (entry == null) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    return XmlTextDecoder.decode(BookImportParsingSupport.archiveBytes(entry));
  }

  BookProject _parseArchive(BookImportFile file, DateTime timestamp) {
    final archive = ZipDecoder().decodeBytes(file.bytes);
    final entry = archive.files.where((candidate) {
      return candidate.isFile && candidate.name.toLowerCase().endsWith('.fb2');
    }).firstOrNull;
    if (entry == null) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    return _parseSource(
      XmlTextDecoder.decode(BookImportParsingSupport.archiveBytes(entry)),
      file,
      timestamp,
      sourceFormat: 'FB2.ZIP',
    );
  }

  BookProject _parseSource(
    String source,
    BookImportFile file,
    DateTime timestamp, {
    required String sourceFormat,
  }) {
    final document = XmlDocument.parse(
      XmlTextDecoder.normalizeEntities(source),
    );
    if (document.rootElement.name.local != 'FictionBook') {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    final titleInfo = BookImportParsingSupport.firstElement(
      document.rootElement,
      'title-info',
    );
    final title = BookImportParsingSupport.textOf(
      titleInfo,
      'book-title',
    ).ifEmpty(BookImportParsingSupport.baseName(file.name));
    final media = _readMedia(document, titleInfo);
    final body =
        document.rootElement.childElements.where((element) {
          return element.name.local == 'body' &&
              (element.getAttribute('name') ?? '').isEmpty;
        }).firstOrNull ??
        BookImportParsingSupport.directElement(document.rootElement, 'body');
    if (body == null) {
      throw const BookImportException(BookImportFailure.noReadableText);
    }
    final sections = _readSections(body, media, timestamp, title);
    return BookImportParsingSupport.project(
      file: file,
      timestamp: timestamp,
      sourceFormat: sourceFormat,
      metadata: BookMetadata(
        title: title,
        author: _author(
          BookImportParsingSupport.directElement(titleInfo, 'author'),
        ),
        description: BookImportParsingSupport.textOf(titleInfo, 'annotation'),
        languageCode: BookImportParsingSupport.language(
          BookImportParsingSupport.textOf(titleInfo, 'lang'),
        ),
        genre: BookImportParsingSupport.textOf(titleInfo, 'genre'),
        series:
            BookImportParsingSupport.directElement(
              titleInfo,
              'sequence',
            )?.getAttribute('name') ??
            '',
      ),
      sections: sections,
      assets: media.assets,
      coverAssetId: media.coverAssetId,
    );
  }

  List<BookSection> _readSections(
    XmlElement body,
    ImportedBookMedia media,
    DateTime timestamp,
    String bookTitle,
  ) {
    final sections = <BookSection>[];
    var sequence = 0;

    void addSection(XmlElement element, String? parentId, int depth) {
      sequence++;
      final id = 'import-${timestamp.microsecondsSinceEpoch}-section-$sequence';
      final titleElement = BookImportParsingSupport.directElement(
        element,
        'title',
      );
      final title =
          titleElement?.innerText.trim().ifEmpty('Раздел $sequence') ??
          'Раздел $sequence';
      final contentNodes = element.children.where((node) {
        return node is! XmlElement ||
            !const {'title', 'section'}.contains(node.name.local);
      });
      sections.add(
        BookSection(
          id: id,
          title: title,
          type:
              depth == 0 &&
                  element.childElements.any(
                    (child) => child.name.local == 'section',
                  )
              ? BookSectionType.part
              : depth > 1
              ? BookSectionType.scene
              : BookSectionType.chapter,
          status: DraftStatus.complete,
          content: XmlBookContentConverter.convert(
            contentNodes,
            imageResolver: media.resolve,
          ),
          parentId: parentId,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
      for (final child in element.childElements.where(
        (candidate) => candidate.name.local == 'section',
      )) {
        addSection(child, id, depth + 1);
      }
    }

    for (final section in body.childElements.where(
      (element) => element.name.local == 'section',
    )) {
      addSection(section, null, 0);
    }
    if (sections.isEmpty) {
      final content = XmlBookContentConverter.convert(
        body.children.where(
          (node) => node is! XmlElement || node.name.local != 'title',
        ),
        imageResolver: media.resolve,
      );
      if (richDocumentHasContent(content)) {
        sections.add(
          BookSection(
            id: 'import-${timestamp.microsecondsSinceEpoch}-section-1',
            title: bookTitle,
            type: BookSectionType.chapter,
            status: DraftStatus.complete,
            content: content,
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
        );
      }
    }
    return sections;
  }

  ImportedBookMedia _readMedia(XmlDocument document, XmlElement? titleInfo) {
    final assets = <BookAsset>[];
    final sourceToAssetId = <String, String>{};
    var totalBytes = 0;
    for (final binary in BookImportParsingSupport.elements(
      document,
      'binary',
    )) {
      final sourceId = binary.getAttribute('id')?.trim() ?? '';
      final mediaType = BookImportParsingSupport.normalizedImageMediaType(
        binary.getAttribute('content-type') ?? '',
      );
      if (sourceId.isEmpty || mediaType == null) continue;
      try {
        final bytes = base64Decode(
          binary.innerText.replaceAll(RegExp(r'\s+'), ''),
        );
        if (!BookImportParsingSupport.canStoreImage(bytes.length, totalBytes)) {
          continue;
        }
        totalBytes += bytes.length;
        final assetId = 'asset-${assets.length + 1}';
        assets.add(
          BookAsset(
            id: assetId,
            mediaType: mediaType,
            bytes: Uint8List.fromList(bytes),
            sourcePath: sourceId,
          ),
        );
        sourceToAssetId[sourceId.toLowerCase()] = assetId;
      } on FormatException {
        continue;
      }
    }
    final coverSource =
        BookImportParsingSupport.firstElement(
              titleInfo ?? document.rootElement,
              'coverpage',
            )?.descendantElements
            .where((element) => element.name.local.toLowerCase() == 'image')
            .map(BookImportParsingSupport.imageReference)
            .whereType<String>()
            .firstOrNull;
    return ImportedBookMedia(
      assets: assets,
      sourceToAssetId: sourceToAssetId,
      coverAssetId: coverSource == null
          ? null
          : sourceToAssetId[BookImportParsingSupport.cleanImageReference(
              coverSource,
            ).toLowerCase()],
    );
  }

  ImportedBookMedia _readCatalogCover(
    XmlDocument document,
    XmlElement? titleInfo,
  ) {
    final coverSource =
        BookImportParsingSupport.firstElement(
              titleInfo ?? document.rootElement,
              'coverpage',
            )?.descendantElements
            .where((element) => element.name.local.toLowerCase() == 'image')
            .map(BookImportParsingSupport.imageReference)
            .whereType<String>()
            .firstOrNull;
    if (coverSource == null) {
      return const ImportedBookMedia(
        assets: [],
        sourceToAssetId: {},
        coverAssetId: null,
      );
    }
    final sourceId = BookImportParsingSupport.cleanImageReference(coverSource);
    final binary = BookImportParsingSupport.elements(document, 'binary')
        .where(
          (element) =>
              element.getAttribute('id')?.toLowerCase() ==
              sourceId.toLowerCase(),
        )
        .firstOrNull;
    final mediaType = BookImportParsingSupport.normalizedImageMediaType(
      binary?.getAttribute('content-type') ?? '',
    );
    if (binary == null || mediaType == null) {
      return const ImportedBookMedia(
        assets: [],
        sourceToAssetId: {},
        coverAssetId: null,
      );
    }
    try {
      final bytes = base64Decode(
        binary.innerText.replaceAll(RegExp(r'\s+'), ''),
      );
      if (!BookImportParsingSupport.canStoreImage(bytes.length, 0)) {
        return const ImportedBookMedia(
          assets: [],
          sourceToAssetId: {},
          coverAssetId: null,
        );
      }
      final asset = BookAsset(
        id: 'asset-cover',
        mediaType: mediaType,
        bytes: Uint8List.fromList(bytes),
        sourcePath: sourceId,
      );
      return ImportedBookMedia(
        assets: [asset],
        sourceToAssetId: {sourceId.toLowerCase(): asset.id},
        coverAssetId: asset.id,
      );
    } on FormatException {
      return const ImportedBookMedia(
        assets: [],
        sourceToAssetId: {},
        coverAssetId: null,
      );
    }
  }

  String _author(XmlElement? author) {
    if (author == null) return '';
    final parts = [
      BookImportParsingSupport.textOf(author, 'first-name'),
      BookImportParsingSupport.textOf(author, 'middle-name'),
      BookImportParsingSupport.textOf(author, 'last-name'),
    ].where((part) => part.isNotEmpty).toList();
    return parts.isNotEmpty
        ? parts.join(' ')
        : BookImportParsingSupport.textOf(author, 'nickname');
  }
}
