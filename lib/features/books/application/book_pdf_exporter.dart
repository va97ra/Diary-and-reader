import 'dart:typed_data';

import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/application/book_export_content.dart';
import 'package:dnevnik/features/books/application/book_pdf_content_renderer.dart';
import 'package:dnevnik/features/books/application/book_pdf_font_assets.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

abstract final class BookPdfExporter {
  static Future<BookExportArtifact> create({
    required BookProject project,
    required BookPdfFontAssets fontAssets,
    String? contentsTitle,
  }) async {
    final theme = _theme(project, fontAssets);
    final document = pw.Document(
      pageMode: PdfPageMode.outlines,
      theme: theme,
      title: project.metadata.title,
      author: _optional(project.metadata.author),
      creator: 'Literia Author Studio',
      subject: _optional(project.metadata.description),
      keywords: _optional(project.metadata.genre),
      producer: 'Literia Author Studio',
    );
    final pageFormat = formatFor(project);
    document.addPage(_titlePage(project, pageFormat));

    for (var index = 0; index < project.sections.length; index++) {
      final section = project.sections[index];
      document.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          maxPages: 10000,
          header: (context) => _header(project.metadata.title, section.title),
          footer: _footer,
          build: (_) => [
            pw.Outline(
              name: 'section-${index + 1}',
              title: section.title,
              level: _depth(project.sections, section),
              child: project.layoutSettings.showChapterTitlesInBody
                  ? pw.Text(
                      section.title,
                      style: pw.TextStyle(
                        fontSize: _sectionTitleSize(section.type),
                        fontWeight: pw.FontWeight.bold,
                      ),
                    )
                  : pw.SizedBox(),
            ),
            if (project.layoutSettings.showChapterTitlesInBody) ...[
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey400, thickness: 0.5),
              pw.SizedBox(height: 12),
            ],
            ...BookPdfContentRenderer.build(
              blocks: BookExportContentParser.parse(section.content),
              settings: project.paragraphSettings,
              assets: project.assets,
            ),
          ],
        ),
      );
    }

    if (project.sections.isNotEmpty) {
      document.addPage(
        pw.MultiPage(
          pageFormat: pageFormat,
          maxPages: 1000,
          header: (context) => _header(
            project.metadata.title,
            contentsTitle ?? _defaultContentsTitle(project),
          ),
          footer: _footer,
          build: (_) => [
            pw.Text(
              contentsTitle ?? _defaultContentsTitle(project),
              style: pw.TextStyle(
                fontSize: project.paragraphSettings.fontSizePt * 1.8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            ..._tableOfContents(document.document.outline),
          ],
        ),
        index: 1,
      );
    }

    return BookExportArtifact(
      bytes: await document.save(enableEventLoopBalancing: true),
      extension: 'pdf',
      mimeType: 'application/pdf',
    );
  }

  static PdfPageFormat formatFor(BookProject project) {
    final format = project.layoutSettings.pageFormat;
    return PdfPageFormat(
      format.widthMm * PdfPageFormat.mm,
      format.heightMm * PdfPageFormat.mm,
      marginTop: format.marginTopMm * PdfPageFormat.mm,
      marginRight: format.marginRightMm * PdfPageFormat.mm,
      marginBottom: format.marginBottomMm * PdfPageFormat.mm,
      marginLeft: format.marginLeftMm * PdfPageFormat.mm,
    );
  }

  static pw.ThemeData _theme(BookProject project, BookPdfFontAssets assets) {
    final regular = pw.Font.ttf(ByteData.sublistView(assets.regular));
    final bold = pw.Font.ttf(ByteData.sublistView(assets.bold));
    final italic = pw.Font.ttf(ByteData.sublistView(assets.italic));
    final boldItalic = pw.Font.ttf(ByteData.sublistView(assets.boldItalic));
    final settings = project.paragraphSettings;
    final base = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      italic: italic,
      boldItalic: boldItalic,
    );
    final style = pw.TextStyle(
      fontSize: settings.fontSizePt,
      lineSpacing: settings.fontSizePt * (settings.lineHeight - 1),
    );
    return base.copyWith(defaultTextStyle: style, paragraphStyle: style);
  }

  static pw.Page _titlePage(BookProject project, PdfPageFormat pageFormat) =>
      pw.Page(
        pageFormat: pageFormat,
        build: (_) => pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Spacer(),
            pw.Text(
              project.metadata.title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: project.paragraphSettings.fontSizePt * 2.4,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (project.metadata.subtitle.trim().isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Text(
                project.metadata.subtitle.trim(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: project.paragraphSettings.fontSizePt * 1.25,
                ),
              ),
            ],
            if (project.metadata.author.trim().isNotEmpty) ...[
              pw.SizedBox(height: 36),
              pw.Text(
                project.metadata.author.trim(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: project.paragraphSettings.fontSizePt * 1.1,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
            pw.Spacer(flex: 2),
            if (project.metadata.publisher.trim().isNotEmpty)
              pw.Text(
                project.metadata.publisher.trim(),
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9),
              ),
            if (project.metadata.rights.trim().isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                project.metadata.rights.trim(),
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ],
        ),
      );

  static pw.Widget _header(String bookTitle, String sectionTitle) =>
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        margin: const pw.EdgeInsets.only(bottom: 10),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.4),
          ),
        ),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                bookTitle,
                maxLines: 1,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Text(
              sectionTitle,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ),
      );

  static pw.Widget _footer(pw.Context context) => pw.Container(
    alignment: pw.Alignment.center,
    padding: const pw.EdgeInsets.only(top: 8),
    child: pw.Text(
      '${context.pageNumber} / ${context.pagesCount}',
      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
    ),
  );

  static List<pw.Widget> _tableOfContents(PdfOutline root) {
    final entries = <_PdfOutlineEntry>[];

    void collect(PdfOutline outline, int level) {
      for (final child in outline.outlines) {
        if (child.title != null && child.anchor != null) {
          entries.add(_PdfOutlineEntry(child, level));
        }
        collect(child, level + 1);
      }
    }

    collect(root, 0);
    return entries
        .map(
          (entry) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Link(
              destination: entry.outline.anchor!,
              child: pw.Row(
                children: [
                  pw.SizedBox(width: entry.level * 14.0),
                  pw.Expanded(child: pw.Text(entry.outline.title!)),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Divider(
                      borderStyle: pw.BorderStyle.dotted,
                      thickness: 0.3,
                      color: PdfColors.grey500,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.DelayedWidget(
                    build: (_) => pw.Text('${entry.outline.page}'),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  static int _depth(List<BookSection> sections, BookSection section) {
    var depth = 0;
    var parentId = section.parentId;
    final visited = <String>{section.id};
    while (parentId != null && visited.add(parentId)) {
      final parent = sections
          .where((candidate) => candidate.id == parentId)
          .firstOrNull;
      if (parent == null) break;
      depth++;
      parentId = parent.parentId;
    }
    return depth.clamp(0, 8);
  }

  static double _sectionTitleSize(BookSectionType type) => switch (type) {
    BookSectionType.part => 24,
    BookSectionType.chapter => 20,
    BookSectionType.scene => 16,
  };

  static String _defaultContentsTitle(BookProject project) =>
      project.metadata.languageCode == 'en' ? 'Contents' : 'Оглавление';

  static String? _optional(String value) =>
      value.trim().isEmpty ? null : value.trim();
}

class _PdfOutlineEntry {
  const _PdfOutlineEntry(this.outline, this.level);

  final PdfOutline outline;
  final int level;
}
