import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/application/epub_rich_text_renderer.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';

abstract final class BookEpubExporter {
  static BookExportArtifact create(BookProject project) {
    final archive = Archive();
    const mediaType = 'application/epub+zip';
    final mediaBytes = utf8.encode(mediaType);
    archive.add(
      ArchiveFile.noCompress('mimetype', mediaBytes.length, mediaBytes),
    );
    archive.add(
      ArchiveFile.string('META-INF/container.xml', _containerDocument),
    );
    archive.add(
      ArchiveFile.string('EPUB/styles/book.css', _stylesheet(project)),
    );
    archive.add(
      ArchiveFile.string('EPUB/text/title.xhtml', _titlePage(project)),
    );
    for (final asset in project.assets.where(
      (asset) => asset.isRenderableImage,
    )) {
      archive.add(
        ArchiveFile(
          'EPUB/images/${_imageFileName(project, asset.id)}',
          asset.bytes.length,
          asset.bytes,
        ),
      );
    }

    for (var index = 0; index < project.sections.length; index++) {
      archive.add(
        ArchiveFile.string(
          'EPUB/text/${_sectionFile(index)}',
          _sectionPage(project, project.sections[index], index),
        ),
      );
    }
    archive.add(ArchiveFile.string('EPUB/nav.xhtml', _navigation(project)));
    archive.add(ArchiveFile.string('EPUB/package.opf', _package(project)));

    return BookExportArtifact(
      bytes: Uint8List.fromList(
        ZipEncoder().encodeBytes(archive, modified: project.updatedAt.toUtc()),
      ),
      extension: 'epub',
      mimeType: mediaType,
    );
  }

  static String _package(BookProject project) {
    final metadata = project.metadata;
    final manifest = StringBuffer()
      ..writeln(
        '    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>',
      )
      ..writeln(
        '    <item id="css" href="styles/book.css" media-type="text/css"/>',
      )
      ..writeln(
        '    <item id="title-page" href="text/title.xhtml" media-type="application/xhtml+xml"/>',
      );
    final spine = StringBuffer()..writeln('    <itemref idref="title-page"/>');
    for (var index = 0; index < project.sections.length; index++) {
      manifest.writeln(
        '    <item id="section-$index" href="text/${_sectionFile(index)}" media-type="application/xhtml+xml"/>',
      );
      spine.writeln('    <itemref idref="section-$index"/>');
    }
    for (var index = 0; index < project.assets.length; index++) {
      final asset = project.assets[index];
      if (!asset.isRenderableImage) continue;
      final coverProperty = asset.id == project.coverAssetId
          ? ' properties="cover-image"'
          : '';
      manifest.writeln(
        '    <item id="image-$index" href="images/${_imageFileName(project, asset.id)}" media-type="${escapeXml(asset.mediaType)}"$coverProperty/>',
      );
    }

    return '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id" xml:lang="${escapeXml(metadata.languageCode)}">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="pub-id">urn:dnevnik:${escapeXml(project.id)}</dc:identifier>
    <dc:title>${escapeXml(metadata.title)}</dc:title>
    <dc:language>${escapeXml(metadata.languageCode)}</dc:language>
    ${_metadataElement('dc:creator', metadata.author)}
    ${_metadataElement('dc:description', metadata.description)}
    ${_metadataElement('dc:publisher', metadata.publisher)}
    ${_metadataElement('dc:rights', metadata.rights)}
    ${_metadataElement('dc:subject', metadata.genre)}
    ${_metadataElement('dc:identifier', metadata.isbn, attributes: ' id="isbn"')}
    ${_seriesMetadata(metadata.series)}
    <meta property="dcterms:modified">${_epubDate(project.updatedAt)}</meta>
  </metadata>
  <manifest>
$manifest  </manifest>
  <spine>
$spine  </spine>
</package>
''';
  }

  static String _navigation(BookProject project) {
    final items = <String>[
      '        <li><a href="text/title.xhtml">${escapeXml(project.metadata.title)}</a></li>',
      ..._navigationTree(project.sections),
    ];
    return _xhtml(
      languageCode: project.metadata.languageCode,
      title: project.metadata.title,
      body:
          '''
  <nav epub:type="toc" id="toc">
    <h1>${escapeXml(project.metadata.title)}</h1>
    <ol>
${items.join('\n')}
    </ol>
  </nav>''',
      includeEpubNamespace: true,
      stylesheetHref: 'styles/book.css',
    );
  }

  static List<String> _navigationTree(List<BookSection> sections) {
    final byParent = <String?, List<int>>{};
    final ids = sections.map((section) => section.id).toSet();
    for (var index = 0; index < sections.length; index++) {
      final requestedParent = sections[index].parentId;
      final parent = requestedParent != null && ids.contains(requestedParent)
          ? requestedParent
          : null;
      byParent.putIfAbsent(parent, () => []).add(index);
    }
    final visited = <int>{};

    String item(int index, int depth) {
      if (!visited.add(index)) return '';
      final section = sections[index];
      final children = byParent[section.id] ?? const <int>[];
      final indent = '        ${List.filled(depth, '  ').join()}';
      final nested = children
          .map((child) => item(child, depth + 1))
          .where((value) => value.isNotEmpty)
          .toList();
      final link =
          '<a href="text/${_sectionFile(index)}">${escapeXml(section.title)}</a>';
      if (nested.isEmpty) return '$indent<li>$link</li>';
      return '$indent<li>$link\n$indent  <ol>\n${nested.join('\n')}\n$indent  </ol>\n$indent</li>';
    }

    final output = <String>[];
    for (final index in byParent[null] ?? const <int>[]) {
      final value = item(index, 0);
      if (value.isNotEmpty) output.add(value);
    }
    for (var index = 0; index < sections.length; index++) {
      if (!visited.contains(index)) output.add(item(index, 0));
    }
    return output;
  }

  static String _titlePage(BookProject project) {
    final metadata = project.metadata;
    final cover = project.coverAsset;
    final coverImage = cover == null
        ? ''
        : '<img class="book-cover" src="../images/${_imageFileName(project, cover.id)}" alt="${escapeXml(metadata.title)}"/>';
    return _xhtml(
      languageCode: metadata.languageCode,
      title: metadata.title,
      body:
          '''
  <section class="title-page" epub:type="titlepage">
    $coverImage
    <h1>${escapeXml(metadata.title)}</h1>
    ${_htmlElement('p', metadata.subtitle, className: 'subtitle')}
    ${_htmlElement('p', metadata.author, className: 'author')}
    ${_htmlElement('p', metadata.description, className: 'description')}
  </section>''',
      includeEpubNamespace: true,
    );
  }

  static String _sectionPage(
    BookProject project,
    BookSection section,
    int index,
  ) => _xhtml(
    languageCode: project.metadata.languageCode,
    title: section.title,
    body:
        '''
  <section id="section-${index + 1}" epub:type="${_epubType(section.type)}">
    ${project.layoutSettings.showChapterTitlesInBody ? '<h1>${escapeXml(section.title)}</h1>' : ''}
${EpubRichTextRenderer.render(section.content, imageSource: (assetId) {
          final file = _imageFileName(project, assetId);
          return file.isEmpty ? null : '../images/$file';
        })}  </section>''',
    includeEpubNamespace: true,
  );

  static String _xhtml({
    required String languageCode,
    required String title,
    required String body,
    String stylesheetHref = '../styles/book.css',
    bool includeEpubNamespace = false,
  }) =>
      '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml"${includeEpubNamespace ? ' xmlns:epub="http://www.idpf.org/2007/ops"' : ''} lang="${escapeXml(languageCode)}" xml:lang="${escapeXml(languageCode)}">
<head>
  <meta charset="UTF-8"/>
  <title>${escapeXml(title)}</title>
  <link rel="stylesheet" type="text/css" href="$stylesheetHref"/>
</head>
<body>
$body
</body>
</html>
''';

  static String _stylesheet(BookProject project) {
    final settings = project.paragraphSettings;
    final font = settings.fontFamily.replaceAll('"', '');
    return '''@charset "UTF-8";
body {
  font-family: "$font", serif;
  font-size: ${_number(settings.fontSizePt)}pt;
  line-height: ${_number(settings.lineHeight)};
  margin: 5%;
  widows: 2;
  orphans: 2;
}
p {
  margin: ${_number(settings.spacingBeforePt)}pt 0 ${_number(settings.spacingAfterPt)}pt;
  text-indent: ${_number(settings.paragraphIndentMm)}mm;
}
h1, h2, h3, h4 { text-indent: 0; page-break-after: avoid; }
blockquote { border-left: 0.2em solid #888; margin: 1em 1.5em; padding-left: 1em; }
pre, code { font-family: monospace; white-space: pre-wrap; }
a { color: inherit; }
.title-page { text-align: center; margin-top: 25%; }
.title-page .subtitle { font-size: 1.2em; text-indent: 0; }
.title-page .author { margin-top: 3em; text-indent: 0; }
.title-page .description { margin-top: 4em; text-align: left; text-indent: 0; }
.align-center, .scene-break { text-align: center; text-indent: 0; }
.align-right, .epigraph { text-align: right; }
.align-justify { text-align: justify; }
.check { font-family: sans-serif; }
.book-image { margin: 1.2em 0; text-align: center; }
.book-image img { max-width: 100%; height: auto; }
.book-image figcaption { margin-top: .4em; font-size: .85em; font-style: italic; }
.book-cover { display: block; max-width: 72%; max-height: 70vh; margin: 0 auto 1.5em; }
.page-break { break-after: page; page-break-after: always; }
${[for (var index = 1; index <= 8; index++) '.indent-$index { margin-left: ${index * 1.5}em; }'].join('\n')}
''';
  }

  static String _metadataElement(
    String tag,
    String value, {
    String attributes = '',
  }) => value.trim().isEmpty
      ? ''
      : '<$tag$attributes>${escapeXml(value.trim())}</$tag>';

  static String _seriesMetadata(String value) => value.trim().isEmpty
      ? ''
      : '<meta id="collection" property="belongs-to-collection">${escapeXml(value.trim())}</meta>\n    <meta refines="#collection" property="collection-type">series</meta>';

  static String _htmlElement(
    String tag,
    String value, {
    required String className,
  }) => value.trim().isEmpty
      ? ''
      : '<$tag class="$className">${escapeXml(value.trim())}</$tag>';

  static String _sectionFile(int index) =>
      'section-${(index + 1).toString().padLeft(3, '0')}.xhtml';

  static String _imageFileName(BookProject project, String assetId) {
    final index = project.assets.indexWhere((asset) => asset.id == assetId);
    if (index < 0) return '';
    final extension = switch (project.assets[index].mediaType.toLowerCase()) {
      'image/png' => 'png',
      'image/jpeg' => 'jpg',
      'image/gif' => 'gif',
      'image/webp' => 'webp',
      _ => 'bin',
    };
    return 'image-${index + 1}.$extension';
  }

  static String _epubType(BookSectionType type) => switch (type) {
    BookSectionType.part => 'part',
    BookSectionType.chapter => 'chapter',
    BookSectionType.scene => 'subchapter',
  };

  static String _epubDate(DateTime value) {
    final utc = value.toUtc();
    String two(int part) => part.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-${two(utc.day)}T${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}Z';
  }

  static String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

const _containerDocument = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="EPUB/package.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
''';
