import 'package:dnevnik/features/books/domain/book_project.dart';

class BookDocxHyperlinkRelationship {
  const BookDocxHyperlinkRelationship({required this.id, required this.target});

  final String id;
  final String target;
}

class BookDocxImageRelationship {
  const BookDocxImageRelationship({required this.id, required this.target});

  final String id;
  final String target;
}

abstract final class BookDocxPackageParts {
  static const contentTypes =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="png" ContentType="image/png"/>
  <Default Extension="jpg" ContentType="image/jpeg"/>
  <Default Extension="gif" ContentType="image/gif"/>
  <Default Extension="webp" ContentType="image/webp"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>
  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
  <Override PartName="/word/fontTable.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml"/>
  <Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>
  <Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
''';

  static const packageRelationships =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
''';

  static String documentRelationships(
    List<BookDocxHyperlinkRelationship> hyperlinks,
    List<BookDocxImageRelationship> images,
  ) {
    final external = hyperlinks
        .map(
          (link) =>
              '  <Relationship Id="${docxEscapeXml(link.id)}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="${docxEscapeXml(link.target)}" TargetMode="External"/>',
        )
        .join('\n');
    final embedded = images
        .map(
          (image) =>
              '  <Relationship Id="${docxEscapeXml(image.id)}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="${docxEscapeXml(image.target)}"/>',
        )
        .join('\n');
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable" Target="fontTable.xml"/>
  <Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/>
  <Relationship Id="rId6" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/>
${external.isEmpty ? '' : '$external\n'}${embedded.isEmpty ? '' : '$embedded\n'}</Relationships>
''';
  }

  static String coreProperties(BookProject project) {
    final metadata = project.metadata;
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>${docxEscapeXml(metadata.title)}</dc:title>
  <dc:subject>${docxEscapeXml(metadata.genre)}</dc:subject>
  <dc:creator>${docxEscapeXml(metadata.author)}</dc:creator>
  <cp:keywords>${docxEscapeXml([metadata.genre, metadata.series].where((value) => value.trim().isNotEmpty).join(', '))}</cp:keywords>
  <dc:description>${docxEscapeXml(metadata.description)}</dc:description>
  <cp:lastModifiedBy>Literia Author Studio</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">${_wordDate(project.createdAt)}</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">${_wordDate(project.updatedAt)}</dcterms:modified>
</cp:coreProperties>
''';
  }

  static const appProperties =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Literia Author Studio</Application>
  <DocSecurity>0</DocSecurity>
  <ScaleCrop>false</ScaleCrop>
  <Company></Company>
  <LinksUpToDate>false</LinksUpToDate>
  <SharedDoc>false</SharedDoc>
  <HyperlinksChanged>false</HyperlinksChanged>
  <AppVersion>1.0</AppVersion>
</Properties>
''';

  static String styles(BookProject project) {
    final settings = project.paragraphSettings;
    final font = docxEscapeXml(settings.fontFamily);
    final size = _halfPoints(settings.fontSizePt);
    final line = (settings.lineHeight * 240).round();
    final firstLine = _millimetersToTwips(settings.paragraphIndentMm);
    final before = (settings.spacingBeforePt * 20).round();
    final after = (settings.spacingAfterPt * 20).round();
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault><w:rPr><w:rFonts w:ascii="$font" w:hAnsi="$font" w:eastAsia="$font" w:cs="$font"/><w:sz w:val="$size"/><w:szCs w:val="$size"/><w:lang w:val="${docxEscapeXml(project.metadata.languageCode)}"/></w:rPr></w:rPrDefault>
    <w:pPrDefault><w:pPr><w:spacing w:before="$before" w:after="$after" w:line="$line" w:lineRule="auto"/></w:pPr></w:pPrDefault>
  </w:docDefaults>
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/><w:rPr><w:rFonts w:ascii="$font" w:hAnsi="$font" w:eastAsia="$font" w:cs="$font"/><w:sz w:val="$size"/><w:szCs w:val="$size"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="BodyText"><w:name w:val="Body Text"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:ind w:firstLine="$firstLine"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:jc w:val="center"/><w:spacing w:before="2400" w:after="240"/><w:keepNext/></w:pPr><w:rPr><w:b/><w:sz w:val="64"/><w:szCs w:val="64"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:jc w:val="center"/><w:spacing w:after="720"/></w:pPr><w:rPr><w:i/><w:sz w:val="28"/><w:szCs w:val="28"/></w:rPr></w:style>
  ${_headingStyle('Heading1', 'heading 1', 40, 0)}
  ${_headingStyle('Heading2', 'heading 2', 32, 1)}
  ${_headingStyle('Heading3', 'heading 3', 27, 2)}
  <w:style w:type="paragraph" w:styleId="TOCHeading"><w:name w:val="TOC Heading"/><w:basedOn w:val="Heading1"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="0" w:after="240"/></w:pPr></w:style>
  ${_tocStyle('TOC1', 'toc 1', 0)}
  ${_tocStyle('TOC2', 'toc 2', 360)}
  ${_tocStyle('TOC3', 'toc 3', 720)}
  <w:style w:type="paragraph" w:styleId="Quote"><w:name w:val="Quote"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:ind w:left="720" w:right="360"/><w:pBdr><w:left w:val="single" w:sz="12" w:space="10" w:color="888888"/></w:pBdr><w:spacing w:before="120" w:after="120"/></w:pPr><w:rPr><w:i/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="Code"><w:name w:val="Code"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:ind w:left="360" w:right="360"/><w:shd w:val="clear" w:fill="F2F2F2"/><w:spacing w:before="120" w:after="120"/></w:pPr><w:rPr><w:rFonts w:ascii="Courier New" w:hAnsi="Courier New" w:eastAsia="Courier New" w:cs="Courier New"/><w:sz w:val="20"/><w:szCs w:val="20"/></w:rPr></w:style>
  <w:style w:type="paragraph" w:styleId="BookEpigraph"><w:name w:val="Book Epigraph"/><w:basedOn w:val="Quote"/><w:pPr><w:jc w:val="right"/><w:ind w:left="2160"/></w:pPr></w:style>
  <w:style w:type="paragraph" w:styleId="SceneBreak"><w:name w:val="Scene Break"/><w:basedOn w:val="Normal"/><w:pPr><w:jc w:val="center"/><w:spacing w:before="240" w:after="240"/></w:pPr></w:style>
  <w:style w:type="character" w:styleId="Hyperlink"><w:name w:val="Hyperlink"/><w:unhideWhenUsed/><w:rPr><w:color w:val="0563C1"/><w:u w:val="single"/></w:rPr></w:style>
</w:styles>
''';
  }

  static String numbering(List<int> decimalIds, List<int> bulletIds) {
    String levels({required bool decimal}) => List.generate(9, (level) {
      final left = 720 + level * 360;
      final text = decimal ? '%${level + 1}.' : '-';
      final format = decimal ? 'decimal' : 'bullet';
      return '''    <w:lvl w:ilvl="$level"><w:start w:val="1"/><w:numFmt w:val="$format"/><w:lvlText w:val="$text"/><w:lvlJc w:val="left"/><w:pPr><w:tabs><w:tab w:val="num" w:pos="$left"/></w:tabs><w:ind w:left="$left" w:hanging="360"/></w:pPr></w:lvl>''';
    }).join('\n');

    String instances(List<int> ids, int abstractId) => ids
        .map(
          (id) =>
              '  <w:num w:numId="$id"><w:abstractNumId w:val="$abstractId"/></w:num>',
        )
        .join('\n');

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:abstractNum w:abstractNumId="0"><w:multiLevelType w:val="multilevel"/><w:name w:val="Book Decimal"/>
${levels(decimal: true)}
  </w:abstractNum>
  <w:abstractNum w:abstractNumId="1"><w:multiLevelType w:val="multilevel"/><w:name w:val="Book Bullet"/>
${levels(decimal: false)}
  </w:abstractNum>
${instances(decimalIds, 0)}${decimalIds.isNotEmpty && bulletIds.isNotEmpty ? '\n' : ''}${instances(bulletIds, 1)}
</w:numbering>
''';
  }

  static const settings =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:zoom w:percent="100"/>
  <w:defaultTabStop w:val="720"/>
  <w:characterSpacingControl w:val="doNotCompress"/>
  <w:updateFields w:val="true"/>
  <w:compat><w:compatSetting w:name="compatibilityMode" w:uri="http://schemas.microsoft.com/office/word" w:val="15"/></w:compat>
</w:settings>
''';

  static String fontTable(BookProject project) {
    final fonts = {
      project.paragraphSettings.fontFamily,
      'Georgia',
      'Times New Roman',
      'Courier New',
    };
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:fonts xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
${fonts.map((font) => '  <w:font w:name="${docxEscapeXml(font)}"><w:family w:val="roman"/><w:charset w:val="00"/></w:font>').join('\n')}
</w:fonts>
''';
  }

  static String header(BookProject project) =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p><w:pPr><w:jc w:val="right"/><w:pBdr><w:bottom w:val="single" w:sz="4" w:space="4" w:color="B7B7B7"/></w:pBdr></w:pPr><w:r><w:rPr><w:color w:val="666666"/><w:sz w:val="18"/><w:szCs w:val="18"/></w:rPr><w:t>${docxEscapeXml(project.metadata.title)}</w:t></w:r></w:p>
</w:hdr>
''';

  static const footer =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:fldSimple w:instr="PAGE"><w:r><w:rPr><w:color w:val="777777"/><w:sz w:val="18"/></w:rPr><w:t>1</w:t></w:r></w:fldSimple><w:r><w:rPr><w:color w:val="777777"/><w:sz w:val="18"/></w:rPr><w:t xml:space="preserve"> / </w:t></w:r><w:fldSimple w:instr="NUMPAGES"><w:r><w:rPr><w:color w:val="777777"/><w:sz w:val="18"/></w:rPr><w:t>1</w:t></w:r></w:fldSimple></w:p>
</w:ftr>
''';

  static String sectionProperties(BookProject project) {
    final page = project.layoutSettings.pageFormat;
    final landscape = page.widthMm > page.heightMm;
    final width = _millimetersToTwips(page.widthMm);
    final height = _millimetersToTwips(page.heightMm);
    return '''<w:sectPr>
      <w:headerReference w:type="default" r:id="rId5"/>
      <w:footerReference w:type="default" r:id="rId6"/>
      <w:titlePg/>
      <w:pgSz w:w="$width" w:h="$height"${landscape ? ' w:orient="landscape"' : ''}/>
      <w:pgMar w:top="${_millimetersToTwips(page.marginTopMm)}" w:right="${_millimetersToTwips(page.marginRightMm)}" w:bottom="${_millimetersToTwips(page.marginBottomMm)}" w:left="${_millimetersToTwips(page.marginLeftMm)}" w:header="720" w:footer="720" w:gutter="0"/>
      <w:cols w:space="720"/>
      <w:docGrid w:linePitch="360"/>
    </w:sectPr>''';
  }

  static String _headingStyle(String id, String name, int size, int level) =>
      '<w:style w:type="paragraph" w:styleId="$id"><w:name w:val="$name"/><w:basedOn w:val="Normal"/><w:next w:val="BodyText"/><w:qFormat/><w:pPr><w:keepNext/><w:keepLines/><w:spacing w:before="360" w:after="180"/><w:outlineLvl w:val="$level"/></w:pPr><w:rPr><w:b/><w:sz w:val="$size"/><w:szCs w:val="$size"/></w:rPr></w:style>';

  static String _tocStyle(String id, String name, int left) =>
      '<w:style w:type="paragraph" w:styleId="$id"><w:name w:val="$name"/><w:basedOn w:val="Normal"/><w:pPr><w:ind w:left="$left"/><w:tabs><w:tab w:val="right" w:leader="dot" w:pos="9360"/></w:tabs><w:spacing w:after="60"/></w:pPr></w:style>';

  static int _halfPoints(double points) => (points * 2).round();

  static int _millimetersToTwips(double millimeters) =>
      (millimeters * 1440 / 25.4).round();

  static String _wordDate(DateTime value) {
    final date = value.toUtc();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}T${two(date.hour)}:${two(date.minute)}:${two(date.second)}Z';
  }
}

String docxEscapeXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
