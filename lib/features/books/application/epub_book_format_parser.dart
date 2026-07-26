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
    final metadataElement = BookImportParsingSupport.elements(
      package,
      'metadata',
    ).firstOrNull;
    final title = BookImportParsingSupport.textOf(
      metadataElement,
      'title',
    ).ifEmpty(BookImportParsingSupport.baseName(file.name));
    final media = _readMedia(archive, rootPath, package, manifest);
    final navigationTitles = _readNavigationTitles(
      archive,
      rootPath,
      package,
      manifest,
    );
    final sections = _readSections(
      archive,
      rootPath,
      package,
      manifest,
      media,
      timestamp,
      bookTitle: title,
      navigationTitles: navigationTitles,
    );
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

  BookProject parseCatalog(BookImportFile file, DateTime timestamp) {
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
    final metadataElement = BookImportParsingSupport.elements(
      package,
      'metadata',
    ).firstOrNull;
    final title = BookImportParsingSupport.textOf(
      metadataElement,
      'title',
    ).ifEmpty(BookImportParsingSupport.baseName(file.name));
    final cover = _readCatalogCover(archive, rootPath, package, manifest);
    return BookImportParsingSupport.catalogProject(
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
      assets: cover.assets,
      coverAssetId: cover.coverAssetId,
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
    DateTime timestamp, {
    required String bookTitle,
    required Map<String, String> navigationTitles,
  }) {
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
      final navigationTitle = navigationTitles[contentPath.toLowerCase()];
      final fallbackTitle = 'Раздел $sectionNumber';
      final title = [navigationTitle, heading, pageTitle]
          .whereType<String>()
          .map((value) => value.trim())
          .firstWhere(
            (value) =>
                value.isNotEmpty &&
                value.toLowerCase() != bookTitle.trim().toLowerCase(),
            orElse: () => fallbackTitle,
          );
      sections.add(
        BookSection(
          id: 'import-${timestamp.microsecondsSinceEpoch}-section-$sectionNumber',
          title: title,
          type: BookSectionType.chapter,
          status: DraftStatus.complete,
          content: richContent,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }
    final titleCounts = <String, int>{};
    for (final section in sections) {
      final key = section.title.trim().toLowerCase();
      titleCounts[key] = (titleCounts[key] ?? 0) + 1;
    }
    return [
      for (var index = 0; index < sections.length; index++)
        titleCounts[sections[index].title.trim().toLowerCase()]! > 1
            ? sections[index].copyWith(
                title: '${sections[index].title} · ${index + 1}',
              )
            : sections[index],
    ];
  }

  Map<String, String> _readNavigationTitles(
    Archive archive,
    String packagePath,
    XmlDocument package,
    Map<String, XmlElement> manifest,
  ) {
    final result = <String, String>{};
    final navItem = manifest.values.where((item) {
      final properties = item.getAttribute('properties') ?? '';
      return properties.toLowerCase().split(RegExp(r'\s+')).contains('nav');
    }).firstOrNull;
    final navHref = navItem?.getAttribute('href');
    if (navHref != null && navHref.isNotEmpty) {
      final navPath = BookImportParsingSupport.resolveArchivePath(
        packagePath,
        navHref,
      );
      final navFile = BookImportParsingSupport.archiveFile(archive, navPath);
      if (navFile != null) {
        try {
          final document = _parseXml(navFile);
          final navigation = BookImportParsingSupport.elements(document, 'nav')
              .where((element) {
                return element.attributes.any((attribute) {
                  final value = attribute.value.toLowerCase();
                  return (attribute.name.local == 'type' &&
                          value.split(RegExp(r'\s+')).contains('toc')) ||
                      (attribute.name.local == 'role' && value == 'doc-toc');
                });
              })
              .firstOrNull;
          final root = navigation ?? document.rootElement;
          for (final anchor in BookImportParsingSupport.elements(root, 'a')) {
            final href = anchor.getAttribute('href');
            final label = anchor.innerText.trim();
            if (href == null || href.isEmpty || label.isEmpty) continue;
            final path = BookImportParsingSupport.resolveArchivePath(
              navPath,
              href,
            ).toLowerCase();
            result.putIfAbsent(path, () => label);
          }
        } on XmlParserException {
          // A broken navigation document must not make readable book pages fail.
        }
      }
    }

    final ncxItem = manifest.values.where((item) {
      final mediaType = item.getAttribute('media-type')?.toLowerCase();
      return mediaType == 'application/x-dtbncx+xml';
    }).firstOrNull;
    final ncxHref = ncxItem?.getAttribute('href');
    if (ncxHref != null && ncxHref.isNotEmpty) {
      final ncxPath = BookImportParsingSupport.resolveArchivePath(
        packagePath,
        ncxHref,
      );
      final ncxFile = BookImportParsingSupport.archiveFile(archive, ncxPath);
      if (ncxFile != null) {
        try {
          final document = _parseXml(ncxFile);
          for (final point in BookImportParsingSupport.elements(
            document,
            'navPoint',
          )) {
            final content = BookImportParsingSupport.elements(
              point,
              'content',
            ).firstOrNull;
            final source = content?.getAttribute('src');
            final labelElement = BookImportParsingSupport.elements(
              point,
              'navLabel',
            ).firstOrNull;
            final label = labelElement?.innerText.trim() ?? '';
            if (source == null || source.isEmpty || label.isEmpty) continue;
            final path = BookImportParsingSupport.resolveArchivePath(
              ncxPath,
              source,
            ).toLowerCase();
            result.putIfAbsent(path, () => label);
          }
        } on XmlParserException {
          // The XHTML heading and file title remain safe fallbacks.
        }
      }
    }
    return result;
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

  ImportedBookMedia _readCatalogCover(
    Archive archive,
    String packagePath,
    XmlDocument package,
    Map<String, XmlElement> manifest,
  ) {
    String? coverId = manifest.entries
        .where((entry) {
          final properties =
              entry.value
                  .getAttribute('properties')
                  ?.toLowerCase()
                  .split(RegExp(r'\s+')) ??
              const <String>[];
          return properties.contains('cover-image');
        })
        .map((entry) => entry.key)
        .firstOrNull;
    coverId ??= BookImportParsingSupport.elements(package, 'meta')
        .where(
          (element) => element.getAttribute('name')?.toLowerCase() == 'cover',
        )
        .map((element) => element.getAttribute('content'))
        .whereType<String>()
        .firstOrNull;
    coverId ??= manifest.entries
        .where((entry) {
          final href = entry.value.getAttribute('href')?.toLowerCase() ?? '';
          return href.contains('cover') &&
              BookImportParsingSupport.normalizedImageMediaType(
                    entry.value.getAttribute('media-type') ?? '',
                  ) !=
                  null;
        })
        .map((entry) => entry.key)
        .firstOrNull;
    final item = manifest[coverId];
    final mediaType = BookImportParsingSupport.normalizedImageMediaType(
      item?.getAttribute('media-type') ?? '',
    );
    final href = item?.getAttribute('href');
    if (mediaType == null || href == null || href.isEmpty) {
      return const ImportedBookMedia(
        assets: [],
        sourceToAssetId: {},
        coverAssetId: null,
      );
    }
    final path = BookImportParsingSupport.resolveArchivePath(packagePath, href);
    final entry = BookImportParsingSupport.archiveFile(archive, path);
    if (entry == null ||
        !BookImportParsingSupport.canStoreImage(entry.size, 0)) {
      return const ImportedBookMedia(
        assets: [],
        sourceToAssetId: {},
        coverAssetId: null,
      );
    }
    final asset = BookAsset(
      id: 'asset-cover',
      mediaType: mediaType,
      bytes: BookImportParsingSupport.archiveBytes(entry),
      sourcePath: path,
    );
    return ImportedBookMedia(
      assets: [asset],
      sourceToAssetId: {path.toLowerCase(): asset.id},
      coverAssetId: asset.id,
    );
  }
}
