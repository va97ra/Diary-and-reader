import 'dart:math' as math;

import 'package:dnevnik/features/books/application/book_docx_package_parts.dart';
import 'package:dnevnik/features/books/application/book_export_content.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_image_placement.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:pdf/widgets.dart' as pw;

class BookDocxEmbeddedImage {
  const BookDocxEmbeddedImage({
    required this.drawingId,
    required this.relationship,
    required this.asset,
  });

  final int drawingId;
  final BookDocxImageRelationship relationship;
  final BookAsset asset;
}

class BookDocxRenderedContent {
  const BookDocxRenderedContent({
    required this.documentXml,
    required this.relationships,
    required this.decimalNumberingIds,
    required this.bulletNumberingIds,
    required this.images,
  });

  final String documentXml;
  final List<BookDocxHyperlinkRelationship> relationships;
  final List<int> decimalNumberingIds;
  final List<int> bulletNumberingIds;
  final List<BookDocxEmbeddedImage> images;
}

abstract final class BookDocxContentRenderer {
  static BookDocxRenderedContent render(BookProject project) {
    final context = _DocxRenderContext(project);
    return context.render();
  }
}

class _DocxRenderContext {
  _DocxRenderContext(this.project)
    : _sectionById = {
        for (final section in project.sections) section.id: section,
      };

  final BookProject project;
  final Map<String, BookSection> _sectionById;
  final _relationships = <BookDocxHyperlinkRelationship>[];
  final _relationshipByTarget = <String, String>{};
  final _decimalNumberingIds = <int>[];
  final _bulletNumberingIds = <int>[];
  final _images = <BookDocxEmbeddedImage>[];
  final _imageByAssetId = <String, BookDocxEmbeddedImage>{};
  var _nextRelationshipId = 100;
  var _nextNumberingId = 10;

  BookDocxRenderedContent render() {
    final body = StringBuffer()
      ..writeln(_titlePage())
      ..writeln(_tableOfContents());
    for (var index = 0; index < project.sections.length; index++) {
      body.writeln(_section(project.sections[index], index));
    }
    body.writeln(BookDocxPackageParts.sectionProperties(project));
    final document =
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
  <w:body>
$body  </w:body>
</w:document>
''';
    return BookDocxRenderedContent(
      documentXml: document,
      relationships: List.unmodifiable(_relationships),
      decimalNumberingIds: List.unmodifiable(_decimalNumberingIds),
      bulletNumberingIds: List.unmodifiable(_bulletNumberingIds),
      images: List.unmodifiable(_images),
    );
  }

  String _titlePage() {
    final metadata = project.metadata;
    final output = StringBuffer();
    if (project.coverAsset != null) {
      output.writeln(
        _imageParagraph(
          BookExportBlock(
            type: BookExportBlockType.image,
            runs: const [],
            assetId: project.coverAsset!.id,
            imageWidthPercent: 75,
          ),
        ),
      );
    }
    output.writeln(_simpleParagraph(metadata.title, style: 'Title'));
    if (metadata.subtitle.trim().isNotEmpty) {
      output.writeln(_simpleParagraph(metadata.subtitle, style: 'Subtitle'));
    }
    if (metadata.author.trim().isNotEmpty) {
      output.writeln(
        _simpleParagraph(
          metadata.author,
          alignment: BookExportTextAlignment.center,
          beforeTwips: 720,
        ),
      );
    }
    if (metadata.publisher.trim().isNotEmpty) {
      output.writeln(
        _simpleParagraph(
          metadata.publisher,
          alignment: BookExportTextAlignment.center,
          beforeTwips: 1800,
        ),
      );
    }
    if (metadata.rights.trim().isNotEmpty) {
      output.writeln(
        _simpleParagraph(
          metadata.rights,
          alignment: BookExportTextAlignment.center,
        ),
      );
    }
    output.writeln(_pageBreak());
    return output.toString();
  }

  String _tableOfContents() {
    final title = project.metadata.languageCode.toLowerCase().startsWith('ru')
        ? 'Оглавление'
        : 'Contents';
    final output = StringBuffer()
      ..writeln(_simpleParagraph(title, style: 'TOCHeading'))
      ..writeln(
        '<w:p><w:r><w:fldChar w:fldCharType="begin" w:dirty="true"/></w:r><w:r><w:instrText xml:space="preserve"> TOC \\o &quot;1-3&quot; \\h \\z \\u </w:instrText></w:r><w:r><w:fldChar w:fldCharType="separate"/></w:r></w:p>',
      );
    for (var index = 0; index < project.sections.length; index++) {
      final section = project.sections[index];
      final level = _outlineLevel(section);
      final bookmark = _bookmark(index);
      output.writeln(
        '<w:p><w:pPr><w:pStyle w:val="TOC${level + 1}"/></w:pPr><w:hyperlink w:anchor="$bookmark" w:history="1"><w:r><w:rPr><w:rStyle w:val="Hyperlink"/></w:rPr><w:t>${_text(section.title)}</w:t></w:r></w:hyperlink><w:r><w:tab/></w:r><w:fldSimple w:instr="PAGEREF $bookmark \\h"><w:r><w:t>?</w:t></w:r></w:fldSimple></w:p>',
      );
    }
    output
      ..writeln('<w:p><w:r><w:fldChar w:fldCharType="end"/></w:r></w:p>')
      ..writeln(_pageBreak());
    return output.toString();
  }

  String _section(BookSection section, int index) {
    final level = _outlineLevel(section);
    final bookmark = _bookmark(index);
    final showTitle = project.layoutSettings.showChapterTitlesInBody;
    final pageBreak = section.type == BookSectionType.scene
        ? ''
        : '<w:pageBreakBefore/>';
    final titleProperties = showTitle
        ? '<w:pStyle w:val="Heading${level + 1}"/>$pageBreak'
        : '<w:pStyle w:val="BodyText"/>$pageBreak';
    final titleRun = showTitle
        ? '<w:r><w:t>${_text(section.title)}</w:t></w:r>'
        : '<w:r><w:t xml:space="preserve"> </w:t></w:r>';
    final output = StringBuffer()
      ..writeln(
        '<w:p><w:pPr>$titleProperties</w:pPr><w:bookmarkStart w:id="${index + 1}" w:name="$bookmark"/>$titleRun<w:bookmarkEnd w:id="${index + 1}"/></w:p>',
      );
    final blocks = BookExportContentParser.parse(section.content);
    BookExportBlockType? activeListType;
    int? activeNumberingId;
    for (final block in blocks) {
      if (block.type == BookExportBlockType.orderedListItem ||
          block.type == BookExportBlockType.bulletListItem) {
        if (activeListType != block.type) {
          activeListType = block.type;
          activeNumberingId = _allocateNumbering(
            decimal: block.type == BookExportBlockType.orderedListItem,
          );
        }
      } else {
        activeListType = null;
        activeNumberingId = null;
      }
      output.writeln(_block(block, activeNumberingId));
    }
    return output.toString();
  }

  String _block(BookExportBlock block, int? numberingId) {
    if (block.type == BookExportBlockType.pageBreak) return _pageBreak();
    if (block.type == BookExportBlockType.image) {
      return _imageParagraph(block);
    }
    final settings = project.paragraphSettings;
    final paragraphProperties = _paragraphProperties(
      block,
      settings,
      numberingId,
    );
    final output = StringBuffer('<w:p><w:pPr>$paragraphProperties</w:pPr>');
    if (block.type == BookExportBlockType.checkedListItem ||
        block.type == BookExportBlockType.uncheckedListItem) {
      output.write(
        _plainRun(
          block.type == BookExportBlockType.checkedListItem ? '[x] ' : '[ ] ',
          bold: block.type == BookExportBlockType.checkedListItem,
        ),
      );
    }
    if (block.runs.isEmpty) {
      output.write('<w:r><w:t xml:space="preserve"> </w:t></w:r>');
    } else {
      for (final run in block.runs) {
        output.write(_run(run, settings, block.type));
      }
    }
    output.write('</w:p>');
    return output.toString();
  }

  String _paragraphProperties(
    BookExportBlock block,
    BookParagraphSettings settings,
    int? numberingId,
  ) {
    final style = switch (block.type) {
      BookExportBlockType.heading1 => 'Heading1',
      BookExportBlockType.heading2 => 'Heading2',
      BookExportBlockType.heading3 => 'Heading3',
      BookExportBlockType.quote when block.semanticStyle == 'epigraph' =>
        'BookEpigraph',
      BookExportBlockType.quote => 'Quote',
      BookExportBlockType.code => 'Code',
      BookExportBlockType.paragraph when block.semanticStyle == 'scene-break' =>
        'SceneBreak',
      _ => 'BodyText',
    };
    final left = block.indent * 360;
    final firstLine = block.type == BookExportBlockType.paragraph
        ? _millimetersToTwips(settings.paragraphIndentMm)
        : 0;
    final line = ((block.lineHeight ?? settings.lineHeight) * 240).round();
    final before = (settings.spacingBeforePt * 20).round();
    final after = (settings.spacingAfterPt * 20).round();
    final properties = StringBuffer('<w:pStyle w:val="$style"/>')
      ..write('<w:jc w:val="${_alignment(block.alignment)}"/>')
      ..write(
        '<w:spacing w:before="$before" w:after="$after" w:line="$line" w:lineRule="auto"/>',
      );
    if (left > 0 || firstLine > 0) {
      properties.write(
        '<w:ind${left > 0 ? ' w:left="$left"' : ''}${firstLine > 0 ? ' w:firstLine="$firstLine"' : ''}/>',
      );
    }
    if (numberingId != null) {
      properties.write(
        '<w:numPr><w:ilvl w:val="${block.indent.clamp(0, 8)}"/><w:numId w:val="$numberingId"/></w:numPr>',
      );
    }
    if (block.rightToLeft) properties.write('<w:bidi/>');
    return properties.toString();
  }

  String _run(
    BookExportTextRun run,
    BookParagraphSettings settings,
    BookExportBlockType blockType,
  ) {
    final font = run.code || blockType == BookExportBlockType.code
        ? 'Courier New'
        : run.fontFamily ?? settings.fontFamily;
    final size = ((run.fontSizePt ?? settings.fontSizePt) * 2).round();
    final properties = StringBuffer(
      '<w:rPr><w:rFonts w:ascii="${docxEscapeXml(font)}" w:hAnsi="${docxEscapeXml(font)}" w:eastAsia="${docxEscapeXml(font)}" w:cs="${docxEscapeXml(font)}"/>',
    );
    if (run.bold) properties.write('<w:b/>');
    if (run.italic) properties.write('<w:i/>');
    if (run.underline) properties.write('<w:u w:val="single"/>');
    if (run.strike) properties.write('<w:strike/>');
    if (run.superscript) {
      properties.write('<w:vertAlign w:val="superscript"/>');
    }
    if (run.subscript) {
      properties.write('<w:vertAlign w:val="subscript"/>');
    }
    if (run.code) {
      properties.write('<w:shd w:val="clear" w:fill="EDEDED"/>');
    }
    if (run.link != null) {
      properties.write('<w:rStyle w:val="Hyperlink"/>');
    }
    properties
      ..write('<w:sz w:val="$size"/><w:szCs w:val="$size"/>')
      ..write('</w:rPr>');
    final wordRun =
        '<w:r>$properties<w:t xml:space="preserve">${_text(run.text)}</w:t></w:r>';
    if (run.link == null) return wordRun;
    final relationshipId = _hyperlinkRelationship(run.link!);
    return '<w:hyperlink r:id="$relationshipId" w:history="1">$wordRun</w:hyperlink>';
  }

  String _simpleParagraph(
    String text, {
    String? style,
    BookExportTextAlignment? alignment,
    int? beforeTwips,
  }) {
    final properties = StringBuffer();
    if (style != null) properties.write('<w:pStyle w:val="$style"/>');
    if (alignment != null) {
      properties.write('<w:jc w:val="${_alignment(alignment)}"/>');
    }
    if (beforeTwips != null) {
      properties.write('<w:spacing w:before="$beforeTwips"/>');
    }
    return '<w:p><w:pPr>$properties</w:pPr>${_plainRun(text)}</w:p>';
  }

  String _plainRun(String text, {bool bold = false}) =>
      '<w:r><w:rPr>${bold ? '<w:b/>' : ''}</w:rPr><w:t xml:space="preserve">${_text(text)}</w:t></w:r>';

  String _pageBreak() => '<w:p><w:r><w:br w:type="page"/></w:r></w:p>';

  String _imageParagraph(BookExportBlock block) {
    final asset = project.assetById(block.assetId ?? '');
    if (asset == null || !asset.isRenderableImage) return '';
    final embedded = _imageByAssetId.putIfAbsent(asset.id, () {
      final extension = switch (asset.mediaType.toLowerCase()) {
        'image/png' => 'png',
        'image/jpeg' => 'jpg',
        'image/gif' => 'gif',
        'image/webp' => 'webp',
        _ => 'bin',
      };
      final drawingId = _images.length + 1;
      final relationship = BookDocxImageRelationship(
        id: 'rId${_nextRelationshipId++}',
        target: 'media/image-$drawingId.$extension',
      );
      final value = BookDocxEmbeddedImage(
        drawingId: drawingId,
        relationship: relationship,
        asset: asset,
      );
      _images.add(value);
      return value;
    });
    var width = 640.0;
    var height = 480.0;
    try {
      final image = pw.MemoryImage(asset.bytes);
      width = (image.width ?? 640).toDouble();
      height = (image.height ?? 480).toDouble();
    } catch (_) {}
    final maxWidth = 5486400.0 * block.imageWidthPercent / 100;
    const maxHeight = 4572000.0;
    final naturalWidth = math.max(1.0, width * 9525);
    final naturalHeight = math.max(1.0, height * 9525);
    final scale = math.min(
      1.0,
      math.min(maxWidth / naturalWidth, maxHeight / naturalHeight),
    );
    final cx = (naturalWidth * scale).round();
    final cy = (naturalHeight * scale).round();
    final drawingId = embedded.drawingId;
    final name = docxEscapeXml(
      embedded.asset.sourcePath.isEmpty
          ? 'Image $drawingId'
          : embedded.asset.sourcePath,
    );
    final alignment = switch (block.imageAlignment) {
      BookImageAlignment.left => 'left',
      BookImageAlignment.center => 'center',
      BookImageAlignment.right => 'right',
    };
    final caption = block.imageCaption.isEmpty
        ? ''
        : _simpleParagraph(
            block.imageCaption,
            alignment: BookExportTextAlignment.center,
          );
    return '<w:p><w:pPr><w:jc w:val="$alignment"/></w:pPr><w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0"><wp:extent cx="$cx" cy="$cy"/><wp:docPr id="$drawingId" name="$name"/><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic><pic:nvPicPr><pic:cNvPr id="$drawingId" name="$name"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed="${embedded.relationship.id}"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>$caption';
  }

  int _outlineLevel(BookSection section) {
    if (section.type == BookSectionType.part) return 0;
    var depth = 0;
    var parentId = section.parentId;
    final visited = <String>{section.id};
    while (parentId != null && visited.add(parentId)) {
      final parent = _sectionById[parentId];
      if (parent == null) break;
      depth++;
      parentId = parent.parentId;
    }
    if (section.type == BookSectionType.scene) depth++;
    return depth.clamp(0, 2);
  }

  int _allocateNumbering({required bool decimal}) {
    final id = _nextNumberingId++;
    (decimal ? _decimalNumberingIds : _bulletNumberingIds).add(id);
    return id;
  }

  String _hyperlinkRelationship(String target) =>
      _relationshipByTarget.putIfAbsent(target, () {
        final id = 'rId${_nextRelationshipId++}';
        _relationships.add(
          BookDocxHyperlinkRelationship(id: id, target: target),
        );
        return id;
      });

  String _bookmark(int index) => 'section_${index + 1}';

  String _alignment(BookExportTextAlignment alignment) => switch (alignment) {
    BookExportTextAlignment.left => 'left',
    BookExportTextAlignment.center => 'center',
    BookExportTextAlignment.right => 'right',
    BookExportTextAlignment.justify => 'both',
  };

  int _millimetersToTwips(double millimeters) =>
      (millimeters * 1440 / 25.4).round();

  String _text(String value) {
    final sanitized = value.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'),
      '',
    );
    return docxEscapeXml(sanitized);
  }
}
