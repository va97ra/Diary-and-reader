import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/xml_book_content_converter.dart';
import 'package:dnevnik/features/books/application/xml_text_decoder.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:xml/xml.dart';

abstract final class BookImportParser {
  static BookProject parse(BookImportFile file, {DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    try {
      if (file.bytes.isEmpty || file.bytes.length > 256 * 1024 * 1024) {
        throw const BookImportException(BookImportFailure.invalidFile);
      }
      final format = _detect(file);
      return switch (format) {
        _DetectedFormat.epub => _parseEpub(file, timestamp),
        _DetectedFormat.fb2 => _parseFb2(
          XmlTextDecoder.decode(file.bytes),
          file,
          timestamp,
          sourceFormat: 'FB2',
        ),
        _DetectedFormat.fb2Zip => _parseFb2Zip(file, timestamp),
      };
    } on BookImportException {
      rethrow;
    } on Exception catch (error) {
      throw BookImportException(
        BookImportFailure.invalidFile,
        error.toString(),
      );
    }
  }

  static _DetectedFormat _detect(BookImportFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.epub')) return _DetectedFormat.epub;
    if (name.endsWith('.fb2')) return _DetectedFormat.fb2;
    if (name.endsWith('.fb2.zip')) return _DetectedFormat.fb2Zip;
    if (_isZip(file.bytes)) {
      final archive = ZipDecoder().decodeBytes(file.bytes);
      if (_archiveFile(archive, 'META-INF/container.xml') != null) {
        return _DetectedFormat.epub;
      }
      if (archive.files.any(
        (entry) => entry.name.toLowerCase().endsWith('.fb2'),
      )) {
        return _DetectedFormat.fb2Zip;
      }
    }
    final prefix = utf8.decode(
      file.bytes.take(512).toList(),
      allowMalformed: true,
    );
    if (prefix.contains('<FictionBook')) return _DetectedFormat.fb2;
    throw const BookImportException(BookImportFailure.unsupportedFormat);
  }

  static BookProject _parseFb2Zip(BookImportFile file, DateTime timestamp) {
    final archive = ZipDecoder().decodeBytes(file.bytes);
    final entry = archive.files.where((candidate) {
      return candidate.isFile && candidate.name.toLowerCase().endsWith('.fb2');
    }).firstOrNull;
    if (entry == null) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    return _parseFb2(
      XmlTextDecoder.decode(_archiveBytes(entry)),
      file,
      timestamp,
      sourceFormat: 'FB2.ZIP',
    );
  }

  static BookProject _parseFb2(
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
    final titleInfo = _firstElement(document.rootElement, 'title-info');
    final title = _textOf(
      titleInfo,
      'book-title',
    ).ifEmpty(_baseName(file.name));
    final author = _fb2Author(_directElement(titleInfo, 'author'));
    final media = _fb2Media(document, titleInfo);
    final body =
        document.rootElement.childElements.where((element) {
          return element.name.local == 'body' &&
              (element.getAttribute('name') ?? '').isEmpty;
        }).firstOrNull ??
        _directElement(document.rootElement, 'body');
    if (body == null) {
      throw const BookImportException(BookImportFailure.noReadableText);
    }
    final sections = <BookSection>[];
    var sequence = 0;

    void addSection(XmlElement element, String? parentId, int depth) {
      sequence++;
      final id = 'import-${timestamp.microsecondsSinceEpoch}-section-$sequence';
      final titleElement = _directElement(element, 'title');
      final sectionTitle =
          titleElement?.innerText.trim().ifEmpty('Раздел $sequence') ??
          'Раздел $sequence';
      final contentNodes = element.children.where((node) {
        return node is! XmlElement ||
            !const {'title', 'section'}.contains(node.name.local);
      });
      sections.add(
        BookSection(
          id: id,
          title: sectionTitle,
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
      for (final child in element.childElements.where((candidate) {
        return candidate.name.local == 'section';
      })) {
        addSection(child, id, depth + 1);
      }
    }

    for (final section in body.childElements.where((element) {
      return element.name.local == 'section';
    })) {
      addSection(section, null, 0);
    }
    if (sections.isEmpty) {
      final content = XmlBookContentConverter.convert(
        body.children.where((node) {
          return node is! XmlElement || node.name.local != 'title';
        }),
        imageResolver: media.resolve,
      );
      if (richDocumentHasContent(content)) {
        sections.add(
          BookSection(
            id: 'import-${timestamp.microsecondsSinceEpoch}-section-1',
            title: title,
            type: BookSectionType.chapter,
            status: DraftStatus.complete,
            content: content,
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
        );
      }
    }
    return _project(
      file: file,
      timestamp: timestamp,
      sourceFormat: sourceFormat,
      metadata: BookMetadata(
        title: title,
        author: author,
        description: _textOf(titleInfo, 'annotation'),
        languageCode: _language(_textOf(titleInfo, 'lang')),
        genre: _textOf(titleInfo, 'genre'),
        series:
            _directElement(titleInfo, 'sequence')?.getAttribute('name') ?? '',
      ),
      sections: sections,
      assets: media.assets,
      coverAssetId: media.coverAssetId,
    );
  }

  static BookProject _parseEpub(BookImportFile file, DateTime timestamp) {
    final archive = ZipDecoder().decodeBytes(file.bytes);
    final containerFile = _archiveFile(archive, 'META-INF/container.xml');
    if (containerFile == null) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    final container = XmlDocument.parse(
      XmlTextDecoder.normalizeEntities(
        XmlTextDecoder.decode(_archiveBytes(containerFile)),
      ),
    );
    final rootPath = _elements(container, 'rootfile')
        .map((element) => element.getAttribute('full-path'))
        .whereType<String>()
        .firstOrNull;
    if (rootPath == null || rootPath.isEmpty) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    final packageFile = _archiveFile(archive, rootPath);
    if (packageFile == null) {
      throw const BookImportException(BookImportFailure.invalidFile);
    }
    final package = XmlDocument.parse(
      XmlTextDecoder.normalizeEntities(
        XmlTextDecoder.decode(_archiveBytes(packageFile)),
      ),
    );
    final manifest = <String, XmlElement>{
      for (final item in _elements(package, 'item'))
        ?item.getAttribute('id'): item,
    };
    final media = _epubMedia(archive, rootPath, package, manifest);
    final itemRefs = _elements(package, 'itemref').toList();
    final linear = itemRefs.where((item) {
      return item.getAttribute('linear')?.toLowerCase() != 'no';
    }).toList();
    final readingOrder = linear.isEmpty ? itemRefs : linear;
    final sections = <BookSection>[];
    var chapterNumber = 0;
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
      final contentPath = _resolveArchivePath(rootPath, href);
      final contentFile = _archiveFile(archive, contentPath);
      if (contentFile == null) continue;
      XmlDocument content;
      try {
        content = XmlDocument.parse(
          XmlTextDecoder.normalizeEntities(
            XmlTextDecoder.decode(_archiveBytes(contentFile)),
          ),
        );
      } on XmlParserException {
        continue;
      }
      final body = _elements(content, 'body').firstOrNull;
      if (body == null) continue;
      final richContent = XmlBookContentConverter.convert(
        body.children,
        imageResolver: (source) {
          final path = _resolveArchivePath(contentPath, source);
          return media.pathToAssetId[path.toLowerCase()];
        },
      );
      if (!richDocumentHasContent(richContent)) continue;
      chapterNumber++;
      final heading = body.descendantElements
          .where((element) {
            return RegExp(
              r'^h[1-6]$',
            ).hasMatch(element.name.local.toLowerCase());
          })
          .map((element) => element.innerText.trim())
          .where((text) {
            return text.isNotEmpty;
          })
          .firstOrNull;
      final pageTitle = _textOf(content.rootElement, 'title');
      sections.add(
        BookSection(
          id: 'import-${timestamp.microsecondsSinceEpoch}-section-$chapterNumber',
          title: heading ?? pageTitle.ifEmpty('Раздел $chapterNumber'),
          type: BookSectionType.chapter,
          status: DraftStatus.complete,
          content: richContent,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }
    final metadataElement = _elements(package, 'metadata').firstOrNull;
    final title = _textOf(
      metadataElement,
      'title',
    ).ifEmpty(_baseName(file.name));
    return _project(
      file: file,
      timestamp: timestamp,
      sourceFormat: 'EPUB',
      metadata: BookMetadata(
        title: title,
        author: _textOf(metadataElement, 'creator'),
        description: _textOf(metadataElement, 'description'),
        languageCode: _language(_textOf(metadataElement, 'language')),
        genre: _textOf(metadataElement, 'subject'),
        publisher: _textOf(metadataElement, 'publisher'),
        rights: _textOf(metadataElement, 'rights'),
      ),
      sections: sections,
      assets: media.assets,
      coverAssetId: media.coverAssetId,
    );
  }

  static BookProject _project({
    required BookImportFile file,
    required DateTime timestamp,
    required String sourceFormat,
    required BookMetadata metadata,
    required List<BookSection> sections,
    List<BookAsset> assets = const [],
    String? coverAssetId,
  }) {
    if (sections.isEmpty) {
      throw const BookImportException(BookImportFailure.noReadableText);
    }
    return BookProject(
      id: 'imported-${timestamp.microsecondsSinceEpoch}',
      metadata: metadata,
      sections: sections,
      activeSectionId: sections.first.id,
      createdAt: timestamp,
      updatedAt: timestamp,
      paragraphSettings: BookParagraphSettings.forPreset(
        BookParagraphPreset.modern,
      ),
      readerProgress: BookReaderProgress(sectionId: sections.first.id),
      kind: BookProjectKind.importedBook,
      sourceFormat: sourceFormat,
      sourceFileName: file.name,
      assets: assets,
      coverAssetId: coverAssetId,
    );
  }

  static _ImportedMedia _fb2Media(XmlDocument document, XmlElement? titleInfo) {
    final assets = <BookAsset>[];
    final sourceToAssetId = <String, String>{};
    var totalBytes = 0;
    for (final binary in _elements(document, 'binary')) {
      final sourceId = binary.getAttribute('id')?.trim() ?? '';
      final mediaType = _normalizedImageMediaType(
        binary.getAttribute('content-type') ?? '',
      );
      if (sourceId.isEmpty || mediaType == null) continue;
      try {
        final bytes = base64Decode(
          binary.innerText.replaceAll(RegExp(r'\s+'), ''),
        );
        if (!_canStoreImage(bytes.length, totalBytes)) continue;
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
        _firstElement(titleInfo ?? document.rootElement, 'coverpage')
            ?.descendantElements
            .where((element) {
              return element.name.local.toLowerCase() == 'image';
            })
            .map(_imageReference)
            .whereType<String>()
            .firstOrNull;
    return _ImportedMedia(
      assets: assets,
      sourceToAssetId: sourceToAssetId,
      coverAssetId: coverSource == null
          ? null
          : sourceToAssetId[_cleanImageReference(coverSource).toLowerCase()],
    );
  }

  static _ImportedMedia _epubMedia(
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
      final mediaType = _normalizedImageMediaType(
        item.getAttribute('media-type') ?? '',
      );
      final href = item.getAttribute('href');
      if (mediaType == null || href == null || href.isEmpty) continue;
      final path = _resolveArchivePath(packagePath, href);
      final file = _archiveFile(archive, path);
      if (file == null || !_canStoreImage(file.size, totalBytes)) continue;
      final bytes = _archiveBytes(file);
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
      final epub2CoverId = _elements(package, 'meta')
          .where((element) {
            return element.getAttribute('name')?.toLowerCase() == 'cover';
          })
          .map((element) => element.getAttribute('content'))
          .whereType<String>()
          .firstOrNull;
      coverAssetId = manifestIdToAssetId[epub2CoverId];
    }
    if (coverAssetId == null) {
      final guideCoverHref = _elements(package, 'reference')
          .where((element) {
            return element.getAttribute('type')?.toLowerCase() == 'cover';
          })
          .map((element) => element.getAttribute('href'))
          .whereType<String>()
          .firstOrNull;
      if (guideCoverHref != null) {
        final path = _resolveArchivePath(packagePath, guideCoverHref);
        coverAssetId = pathToAssetId[path.toLowerCase()];
      }
    }
    return _ImportedMedia(
      assets: assets,
      sourceToAssetId: pathToAssetId,
      coverAssetId: coverAssetId,
    );
  }

  static String? _imageReference(XmlElement element) => element.attributes
      .where((attribute) {
        final name = attribute.name.local.toLowerCase();
        return name == 'href' || name == 'src';
      })
      .map((attribute) => attribute.value.trim())
      .where((value) => value.isNotEmpty)
      .firstOrNull;

  static String _cleanImageReference(String value) =>
      Uri.decodeComponent(value.split('#').last.trim());

  static String? _normalizedImageMediaType(String value) {
    final normalized = value.trim().toLowerCase().split(';').first;
    return switch (normalized) {
      'image/jpg' => 'image/jpeg',
      'image/jpeg' || 'image/png' || 'image/gif' || 'image/webp' => normalized,
      _ => null,
    };
  }

  static bool _canStoreImage(int bytes, int currentTotal) =>
      bytes > 0 &&
      bytes <= 20 * 1024 * 1024 &&
      currentTotal + bytes <= 128 * 1024 * 1024;

  static String _fb2Author(XmlElement? author) {
    if (author == null) return '';
    final parts = [
      _textOf(author, 'first-name'),
      _textOf(author, 'middle-name'),
      _textOf(author, 'last-name'),
    ].where((part) => part.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' ') : _textOf(author, 'nickname');
  }

  static XmlElement? _firstElement(XmlElement root, String localName) => root
      .descendantElements
      .where((element) => element.name.local == localName)
      .firstOrNull;

  static XmlElement? _directElement(XmlElement? root, String localName) => root
      ?.childElements
      .where((element) => element.name.local == localName)
      .firstOrNull;

  static Iterable<XmlElement> _elements(XmlNode root, String localName) => root
      .descendantElements
      .where((element) => element.name.local == localName);

  static String _textOf(XmlElement? root, String localName) => root == null
      ? ''
      : _elements(root, localName)
                .map((element) => element.innerText.trim())
                .where((text) => text.isNotEmpty)
                .firstOrNull ??
            '';

  static ArchiveFile? _archiveFile(Archive archive, String requestedPath) {
    final normalized = _normalizePath(requestedPath).toLowerCase();
    return archive.files.where((entry) {
      return entry.isFile &&
          _normalizePath(entry.name).toLowerCase() == normalized;
    }).firstOrNull;
  }

  static Uint8List _archiveBytes(ArchiveFile file) =>
      Uint8List.fromList(file.content as List<int>);

  static String _resolveArchivePath(String packagePath, String href) {
    final cleanHref = href.split('#').first;
    final resolved = Uri(path: packagePath).resolve(cleanHref).path;
    return _normalizePath(Uri.decodeComponent(resolved));
  }

  static String _normalizePath(String value) =>
      value.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');

  static bool _isZip(Uint8List bytes) =>
      bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4b;

  static String _baseName(String value) {
    final name = value.replaceAll('\\', '/').split('/').last;
    return name.replaceFirst(
      RegExp(r'\.(fb2\.zip|epub|fb2|zip)$', caseSensitive: false),
      '',
    );
  }

  static String _language(String value) =>
      value.toLowerCase().startsWith('en') ? 'en' : 'ru';
}

enum _DetectedFormat { epub, fb2, fb2Zip }

class _ImportedMedia {
  const _ImportedMedia({
    required this.assets,
    required this.sourceToAssetId,
    required this.coverAssetId,
  });

  final List<BookAsset> assets;
  final Map<String, String> sourceToAssetId;
  final String? coverAssetId;

  Map<String, String> get pathToAssetId => sourceToAssetId;

  String? resolve(String source) =>
      sourceToAssetId[_cleanImportImageReference(source).toLowerCase()];
}

String _cleanImportImageReference(String value) =>
    Uri.decodeComponent(value.split('#').last.trim());

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : trim();
}
