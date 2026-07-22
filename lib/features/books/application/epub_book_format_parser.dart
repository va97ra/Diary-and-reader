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

class EpubBookFormatParser implements BookFormatParser {
  const EpubBookFormatParser();

  @override
  Set<BookImportFormat> get formats => const {BookImportFormat.epub};

  @override
  BookProject parse(
    BookImportFile file,
    DateTime timestamp,
    BookImportFormat format,
  ) {
    final archive = ZipDecoder().decodeBytes(file.bytes);
    final containerFile = BookImportParsingSupport.archiveFile(
      archive,
      'META-INF/container.xml',
    );
    if (containerFile == null) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    final container = _parseXml(containerFile);
    final rootPath = BookImportParsingSupport.elements(container, 'rootfile')
        .map((element) => element.getAttribute('full-path'))
        .whereType<String>()
        .firstOrNull;
    if (rootPath == null || rootPath.isEmpty) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    final packageFile = BookImportParsingSupport.archiveFile(archive, rootPath);
    if (packageFile == null) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    final package = _parseXml(packageFile);
    final manifest = <String, XmlElement>{
      for (final item in BookImportParsingSupport.elements(package, 'item'))
        ?item.getAttribute('id'): item,
    };
    final media = _readMedia(archive, rootPath, package, manifest);
    final sections = _readSections(
      archive,
      rootPath,
      package,
      manifest,
      media,
      timestamp,
    );
    final metadataElement = BookImportParsingSupport.elements(
      package,
      'metadata',
    ).firstOrNull;
    final title = BookImportParsingSupport.textOf(
      metadataElement,
      'title',
    ).ifEmpty(BookImportParsingSupport.baseName(file.name));
    return BookImportParsingSupport.project(
      file: file,
      timestamp: timestamp,
      sourceFormat: 'EPUB',
      metadata: BookMetadata(
        title: title,
        author: BookImportParsingSupport.textOf(metadataElement, 'creator'),
        description: BookImportParsingSupport.textOf(
          metadataElement,
          'description',
        ),
        languageCode: BookImportParsingSupport.language(
          BookImportParsingSupport.textOf(metadataElement, 'language'),
        ),
        genre: BookImportParsingSupport.textOf(metadataElement, 'subject'),
        publisher: BookImportParsingSupport.textOf(
          metadataElement,
          'publisher',
        ),
        rights: BookImportParsingSupport.textOf(metadataElement, 'rights'),
      ),
      sections: sections,
      assets: media.assets,
      coverAssetId: media.coverAssetId,
    );
  }

  XmlDocument _parseXml(ArchiveFile file) => XmlDocument.parse(
    XmlTextDecoder.normalizeEntities(
      XmlTextDecoder.decode(BookImportParsingSupport.archiveBytes(file)),
    ),
  );

  List<BookSection> _readSections(
    Archive archive,
    String rootPath,
    XmlDocument package,
    Map<String, XmlElement> manifest,
    ImportedBookMedia media,
    DateTime timestamp,
  ) {
    final itemRefs = BookImportParsingSupport.elements(
      package,
      'itemref',
    ).toList();
    final linear = itemRefs
        .where((item) => item.getAttribute('linear')?.toLowerCase() != 'no')
        .toList();
    final readingOrder = linear.isEmpty ? itemRefs : linear;
    final sections = <BookSection>[];
    for (final itemRef in readingOrder) {
      final item = manifest[itemRef.getAttribute('idref')];
      final href = item?.getAttribute('href');
      if (href == null || href.isEmpty) continue;
      final mediaType = item?.getAttribute('media-type') ?? '';
      if (mediaType.isNotEmpty &&
          mediaType != 'application/xhtml+xml' &&
          mediaType != 'text/html') {
        continue;
      }
      final contentPath = BookImportParsingSupport.resolveArchivePath(
        rootPath,
        href,
      );
      final contentFile = BookImportParsingSupport.archiveFile(
        archive,
        contentPath,
      );
      if (contentFile == null) continue;
      XmlDocument content;
      try {
        content = _parseXml(contentFile);
      } on XmlParserException {
        continue;
      }
      final body = BookImportParsingSupport.elements(
        content,
        'body',
      ).firstOrNull;
      if (body == null) continue;
      final richContent = XmlBookContentConverter.convert(
        body.children,
        imageResolver: (source) {
          final path = BookImportParsingSupport.resolveArchivePath(
            contentPath,
            source,
          );
          return media.pathToAssetId[path.toLowerCase()];
        },
      );
      if (!richDocumentHasContent(richContent)) continue;
      final sectionNumber = sections.length + 1;
      final heading = body.descendantElements
          .where(
            (element) =>
                RegExp(r'^h[1-6]$').hasMatch(element.name.local.toLowerCase()),
          )
          .map((element) => element.innerText.trim())
          .where((text) => text.isNotEmpty)
          .firstOrNull;
      final pageTitle = BookImportParsingSupport.textOf(
        content.rootElement,
        'title',
      );
      sections.add(
        BookSection(
          id: 'import-${timestamp.microsecondsSinceEpoch}-section-$sectionNumber',
          title: heading ?? pageTitle.ifEmpty('Раздел $sectionNumber'),
          type: BookSectionType.chapter,
          status: DraftStatus.complete,
          content: richContent,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }
    return sections;
  }

  ImportedBookMedia _readMedia(
    Archive archive,
    String packagePath,
    XmlDocument package,
    Map<String, XmlElement> manifest,
  ) {
    final assets = <BookAsset>[];
    final pathToAssetId = <String, String>{};
    final manifestIdToAssetId = <String, String>{};
    var totalBytes = 0;
    for (final entry in manifest.entries) {
      final item = entry.value;
      final mediaType = BookImportParsingSupport.normalizedImageMediaType(
        item.getAttribute('media-type') ?? '',
      );
      final href = item.getAttribute('href');
      if (mediaType == null || href == null || href.isEmpty) continue;
      final path = BookImportParsingSupport.resolveArchivePath(
        packagePath,
        href,
      );
      final file = BookImportParsingSupport.archiveFile(archive, path);
      if (file == null ||
          !BookImportParsingSupport.canStoreImage(file.size, totalBytes)) {
        continue;
      }
      final bytes = BookImportParsingSupport.archiveBytes(file);
      totalBytes += bytes.length;
      final assetId = 'asset-${assets.length + 1}';
      assets.add(
        BookAsset(
          id: assetId,
          mediaType: mediaType,
          bytes: bytes,
          sourcePath: path,
        ),
      );
      pathToAssetId[path.toLowerCase()] = assetId;
      manifestIdToAssetId[entry.key] = assetId;
    }

    String? coverAssetId;
    for (final entry in manifest.entries) {
      final properties = entry.value
          .getAttribute('properties')
          ?.toLowerCase()
          .split(RegExp(r'\s+'));
      if (properties?.contains('cover-image') ?? false) {
        coverAssetId = manifestIdToAssetId[entry.key];
        if (coverAssetId != null) break;
      }
    }
    if (coverAssetId == null) {
      final coverId = BookImportParsingSupport.elements(package, 'meta')
          .where(
            (element) => element.getAttribute('name')?.toLowerCase() == 'cover',
          )
          .map((element) => element.getAttribute('content'))
          .whereType<String>()
          .firstOrNull;
      coverAssetId = manifestIdToAssetId[coverId];
    }
    if (coverAssetId == null) {
      final coverHref = BookImportParsingSupport.elements(package, 'reference')
          .where(
            (element) => element.getAttribute('type')?.toLowerCase() == 'cover',
          )
          .map((element) => element.getAttribute('href'))
          .whereType<String>()
          .firstOrNull;
      if (coverHref != null) {
        final path = BookImportParsingSupport.resolveArchivePath(
          packagePath,
          coverHref,
        );
        coverAssetId = pathToAssetId[path.toLowerCase()];
      }
    }
    return ImportedBookMedia(
      assets: assets,
      sourceToAssetId: pathToAssetId,
      coverAssetId: coverAssetId,
    );
  }
}
