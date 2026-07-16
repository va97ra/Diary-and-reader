import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/application/epub_rich_text_renderer.dart';
import 'package:dnevnik/features/books/application/fb2_rich_text_renderer.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';

abstract final class BookFb2Exporter {
  static const namespace = 'http://www.gribuser.ru/xml/fictionbook/2.0';
  static const linkNamespace = 'http://www.w3.org/1999/xlink';

  static BookExportArtifact create(BookProject project) {
    final bytes = Uint8List.fromList(utf8.encode(_document(project)));
    return BookExportArtifact(
      bytes: bytes,
      extension: 'fb2',
      mimeType: 'application/x-fictionbook+xml',
    );
  }

  static BookExportArtifact createZip(BookProject project) {
    final fb2 = create(project);
    final archive = Archive()
      ..add(ArchiveFile('book.fb2', fb2.bytes.length, fb2.bytes));
    return BookExportArtifact(
      bytes: Uint8List.fromList(
        ZipEncoder().encodeBytes(archive, modified: project.updatedAt.toUtc()),
      ),
      extension: 'fb2.zip',
      mimeType: 'application/zip',
    );
  }

  static String _document(BookProject project) {
    final metadata = project.metadata;
    final date = _date(project.updatedAt);
    final body = _sections(project.sections);
    return '''<?xml version="1.0" encoding="UTF-8"?>
<FictionBook xmlns="$namespace" xmlns:l="$linkNamespace">
  <description>
    <title-info>
      <genre>${_genre(metadata.genre)}</genre>
      ${_author(metadata.author, fallback: 'Неизвестный автор')}
      <book-title>${escapeXml(metadata.title)}</book-title>
      ${_annotation(metadata.description)}
      ${_optionalElement('keywords', metadata.genre)}
      <date value="$date">$date</date>
      <lang>${escapeXml(metadata.languageCode)}</lang>
      ${_sequence(metadata.series)}
    </title-info>
    <document-info>
      ${_author(metadata.author, fallback: 'Дневник')}
      <program-used>Дневник — авторская студия</program-used>
      <date value="$date">$date</date>
      <id>${escapeXml(project.id)}</id>
      <version>1.0</version>
    </document-info>
    ${_publishInfo(metadata, project.updatedAt.year)}
    ${_customInfo('genre', metadata.genre)}
    ${_customInfo('rights', metadata.rights)}
  </description>
  <body>
    <title><p>${escapeXml(metadata.title)}</p></title>
$body  </body>
${_binaries(project)}
</FictionBook>
''';
  }

  static String _sections(List<BookSection> sections) {
    if (sections.isEmpty) return '    <section><p/></section>\n';
    final ids = sections.map((section) => section.id).toSet();
    final byParent = <String?, List<int>>{};
    for (var index = 0; index < sections.length; index++) {
      final requestedParent = sections[index].parentId;
      final parent = requestedParent != null && ids.contains(requestedParent)
          ? requestedParent
          : null;
      byParent.putIfAbsent(parent, () => []).add(index);
    }
    final visited = <int>{};

    String renderSection(int index, int depth) {
      if (!visited.add(index)) return '';
      final section = sections[index];
      final children = byParent[section.id] ?? const <int>[];
      final indent = '    ${List.filled(depth, '  ').join()}';
      final output = StringBuffer()
        ..writeln('$indent<section id="section-${index + 1}">')
        ..writeln('$indent  <title><p>${escapeXml(section.title)}</p></title>');
      final hasText = richDocumentHasContent(section.content);
      if (children.isNotEmpty && hasText) {
        output.writeln('$indent  <section id="section-${index + 1}-text">');
        output.write(_indentedContent(section.content, depth + 2));
        output.writeln('$indent  </section>');
      } else if (children.isEmpty) {
        output.write(
          hasText
              ? _indentedContent(section.content, depth + 1)
              : '$indent  <empty-line/>\n',
        );
      }
      for (final child in children) {
        output.write(renderSection(child, depth + 1));
      }
      output.writeln('$indent</section>');
      return output.toString();
    }

    final output = StringBuffer();
    for (final root in byParent[null] ?? const <int>[]) {
      output.write(renderSection(root, 0));
    }
    for (var index = 0; index < sections.length; index++) {
      if (!visited.contains(index)) output.write(renderSection(index, 0));
    }
    return output.toString();
  }

  static String _indentedContent(RichDocument content, int depth) {
    final prefix = List.filled(depth, '  ').join();
    return Fb2RichTextRenderer.render(
      content,
    ).split('\n').where((line) => line.isNotEmpty).map((line) {
      final trimmed = line.trimLeft();
      return '    $prefix$trimmed\n';
    }).join();
  }

  static String _author(String value, {required String fallback}) {
    final parts = value.trim().split(RegExp(r'\s+')).where((part) {
      return part.isNotEmpty;
    }).toList();
    if (parts.isEmpty) {
      return '<author><first-name/><last-name/><nickname>${escapeXml(fallback)}</nickname></author>';
    }
    if (parts.length == 1) {
      return '<author><first-name/><last-name/><nickname>${escapeXml(parts.single)}</nickname></author>';
    }
    final middle = parts.length > 2
        ? '<middle-name>${escapeXml(parts.sublist(1, parts.length - 1).join(' '))}</middle-name>'
        : '';
    return '<author><first-name>${escapeXml(parts.first)}</first-name>$middle<last-name>${escapeXml(parts.last)}</last-name></author>';
  }

  static String _annotation(String value) => value.trim().isEmpty
      ? ''
      : '<annotation><p>${escapeXml(value.trim())}</p></annotation>';

  static String _sequence(String value) => value.trim().isEmpty
      ? ''
      : '<sequence name="${escapeXml(value.trim())}"/>';

  static String _publishInfo(BookMetadata metadata, int year) {
    if (metadata.publisher.trim().isEmpty && metadata.isbn.trim().isEmpty) {
      return '';
    }
    return '''<publish-info>
      <book-name>${escapeXml(metadata.title)}</book-name>
      ${_optionalElement('publisher', metadata.publisher)}
      <year>$year</year>
      ${_optionalElement('isbn', metadata.isbn)}
    </publish-info>''';
  }

  static String _customInfo(String type, String value) => value.trim().isEmpty
      ? ''
      : '<custom-info info-type="$type">${escapeXml(value.trim())}</custom-info>';

  static String _optionalElement(String tag, String value) =>
      value.trim().isEmpty ? '' : '<$tag>${escapeXml(value.trim())}</$tag>';

  static String _genre(String value) {
    final genre = value.toLowerCase();
    if (genre.contains('фэнтези') || genre.contains('fantasy')) {
      return 'sf_fantasy';
    }
    if (genre.contains('фантаст') || genre.contains('science fiction')) {
      return 'sf_social';
    }
    if (genre.contains('детектив') || genre.contains('detective')) {
      return 'detective_classic';
    }
    if (genre.contains('любов') || genre.contains('romance')) {
      return 'love_contemporary';
    }
    if (genre.contains('поэз') || genre.contains('poetry')) return 'poetry';
    return 'prose_contemporary';
  }

  static String _date(DateTime value) {
    final local = value.toLocal();
    String two(int part) => part.toString().padLeft(2, '0');
    return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-${two(local.day)}';
  }

  static String _binaries(BookProject project) => project.assets
      .where((asset) => asset.isRenderableImage)
      .map(
        (asset) =>
            '  <binary id="${escapeXml(asset.id)}" content-type="${escapeXml(asset.mediaType)}">${base64Encode(asset.bytes)}</binary>',
      )
      .join('\n');
}
