import 'dart:convert';
import 'dart:typed_data';

import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/application/book_section_outline.dart';
import 'package:dnevnik/features/books/application/epub_rich_text_renderer.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';

abstract final class BookHtmlExporter {
  static BookExportArtifact create(BookProject project) {
    final html = _document(project);
    return BookExportArtifact(
      bytes: Uint8List.fromList(utf8.encode(html)),
      extension: 'html',
      mimeType: 'text/html; charset=utf-8',
    );
  }

  static String _document(BookProject project) {
    final metadata = project.metadata;
    final outline = BookSectionOutline.flatten(project.sections);
    final navigation = outline
        .map((entry) {
          final margin = entry.depth * 1.5;
          return '<li style="margin-left:${_number(margin)}em"><a href="#section-${entry.index + 1}">${escapeXml(entry.section.title)}</a></li>';
        })
        .join('\n        ');
    final sections = outline
        .map((entry) {
          final level = (entry.depth + 2).clamp(2, 6);
          return '''<section id="section-${entry.index + 1}" data-type="${entry.section.type.name}">
  <h$level>${escapeXml(entry.section.title)}</h$level>
${EpubRichTextRenderer.render(entry.section.content, imageSource: (assetId) {
            final asset = project.assetById(assetId);
            return asset == null ? null : 'data:${asset.mediaType};base64,${base64Encode(asset.bytes)}';
          })}</section>''';
        })
        .join('\n\n');
    final font = project.paragraphSettings.fontFamily.replaceAll('"', '');
    final settings = project.paragraphSettings;
    return '''<!doctype html>
<html lang="${escapeXml(metadata.languageCode)}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeXml(metadata.title)}</title>
  ${_meta('author', metadata.author)}
  ${_meta('description', metadata.description)}
  <style>
    body { max-width: 48rem; margin: 0 auto; padding: 3rem 1.5rem; font-family: "$font", serif; font-size: ${_number(settings.fontSizePt)}pt; line-height: ${_number(settings.lineHeight)}; color: #202124; }
    header { min-height: 40vh; display: grid; place-content: center; text-align: center; }
    header .subtitle { font-size: 1.25em; }
    header .author { margin-top: 2rem; }
    nav { border-block: 1px solid #bbb; margin-block: 2rem 4rem; padding-block: 1rem; }
    nav ul { list-style: none; padding: 0; }
    nav a { color: inherit; }
    section { margin-block: 3rem; }
    p { margin: ${_number(settings.spacingBeforePt)}pt 0 ${_number(settings.spacingAfterPt)}pt; text-indent: ${_number(settings.paragraphIndentMm)}mm; }
    h1, h2, h3, h4, h5, h6 { text-indent: 0; }
    blockquote { border-left: .2rem solid #888; margin-left: 0; padding-left: 1rem; }
    pre { white-space: pre-wrap; }
    .align-center, .scene-break { text-align: center; text-indent: 0; }
    .align-right, .epigraph { text-align: right; }
    .align-justify { text-align: justify; }
    .book-image { margin: 1.2rem 0; text-align: center; }
    .book-image img { max-width: 100%; height: auto; }
    ${[for (var index = 1; index <= 8; index++) '.indent-$index { margin-left: ${index * 1.5}em; }'].join('\n    ')}
    @media (max-width: 600px) { body { padding: 1.5rem 1rem; } }
  </style>
</head>
<body>
  <header>
    <h1>${escapeXml(metadata.title)}</h1>
    ${_element('p', metadata.subtitle, 'subtitle')}
    ${_element('p', metadata.author, 'author')}
    ${_element('p', metadata.description, 'description')}
  </header>
  <nav aria-label="Table of contents">
    <h2>Оглавление / Contents</h2>
    <ul>
        $navigation
    </ul>
  </nav>
$sections
</body>
</html>
''';
  }

  static String _meta(String name, String value) => value.trim().isEmpty
      ? ''
      : '<meta name="$name" content="${escapeXml(value.trim())}">';

  static String _element(String tag, String value, String className) =>
      value.trim().isEmpty
      ? ''
      : '<$tag class="$className">${escapeXml(value.trim())}</$tag>';

  static String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}
