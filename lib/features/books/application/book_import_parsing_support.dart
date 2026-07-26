import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:xml/xml.dart';

abstract final class BookImportParsingSupport {
  static BookProject project({
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

  static BookProject catalogProject({
    required BookImportFile file,
    required DateTime timestamp,
    required String sourceFormat,
    required BookMetadata metadata,
    List<BookAsset> assets = const [],
    String? coverAssetId,
  }) => BookProject(
    id: 'imported-${timestamp.microsecondsSinceEpoch}',
    metadata: metadata,
    sections: const [],
    activeSectionId: null,
    createdAt: timestamp,
    updatedAt: timestamp,
    paragraphSettings: BookParagraphSettings.forPreset(
      BookParagraphPreset.modern,
    ),
    kind: BookProjectKind.importedBook,
    sourceFormat: sourceFormat,
    sourceFileName: file.name,
    assets: assets,
    coverAssetId: coverAssetId,
  );

  static XmlElement? firstElement(XmlElement root, String localName) => root
      .descendantElements
      .where((element) => element.name.local == localName)
      .firstOrNull;

  static XmlElement? directElement(XmlElement? root, String localName) => root
      ?.childElements
      .where((element) => element.name.local == localName)
      .firstOrNull;

  static Iterable<XmlElement> elements(XmlNode root, String localName) => root
      .descendantElements
      .where((element) => element.name.local == localName);

  static String textOf(XmlElement? root, String localName) => root == null
      ? ''
      : elements(root, localName)
                .map((element) => element.innerText.trim())
                .where((text) => text.isNotEmpty)
                .firstOrNull ??
            '';

  static ArchiveFile? archiveFile(Archive archive, String requestedPath) {
    final normalized = normalizePath(requestedPath).toLowerCase();
    return archive.files.where((entry) {
      return entry.isFile &&
          normalizePath(entry.name).toLowerCase() == normalized;
    }).firstOrNull;
  }

  static Uint8List archiveBytes(ArchiveFile file) =>
      Uint8List.fromList(file.content as List<int>);

  static String resolveArchivePath(String packagePath, String href) {
    final cleanHref = href.split('#').first;
    final resolved = Uri(path: packagePath).resolve(cleanHref).path;
    return normalizePath(Uri.decodeComponent(resolved));
  }

  static String normalizePath(String value) =>
      value.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');

  static String baseName(String value) {
    final name = value.replaceAll('\\', '/').split('/').last;
    return name.replaceFirst(
      RegExp(
        r'\.(fb2\.zip|epub|fb2|zip|txt|rtf|docx|mobi)$',
        caseSensitive: false,
      ),
      '',
    );
  }

  static String language(String value) =>
      value.toLowerCase().startsWith('en') ? 'en' : 'ru';

  static String? imageReference(XmlElement element) => element.attributes
      .where((attribute) {
        final name = attribute.name.local.toLowerCase();
        return name == 'href' || name == 'src';
      })
      .map((attribute) => attribute.value.trim())
      .where((value) => value.isNotEmpty)
      .firstOrNull;

  static String cleanImageReference(String value) =>
      Uri.decodeComponent(value.split('#').last.trim());

  static String? normalizedImageMediaType(String value) {
    final normalized = value.trim().toLowerCase().split(';').first;
    return switch (normalized) {
      'image/jpg' => 'image/jpeg',
      'image/jpeg' || 'image/png' || 'image/gif' || 'image/webp' => normalized,
      _ => null,
    };
  }

  static bool canStoreImage(int bytes, int currentTotal) =>
      bytes > 0 &&
      bytes <= 20 * 1024 * 1024 &&
      currentTotal + bytes <= 128 * 1024 * 1024;
}

class ImportedBookMedia {
  const ImportedBookMedia({
    required this.assets,
    required this.sourceToAssetId,
    required this.coverAssetId,
  });

  final List<BookAsset> assets;
  final Map<String, String> sourceToAssetId;
  final String? coverAssetId;

  Map<String, String> get pathToAssetId => sourceToAssetId;

  String? resolve(String source) =>
      sourceToAssetId[BookImportParsingSupport.cleanImageReference(
        source,
      ).toLowerCase()];
}

extension BookImportString on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : trim();
}
