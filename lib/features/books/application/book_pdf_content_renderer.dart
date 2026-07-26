import 'package:dnevnik/features/books/application/book_export_content.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_image_placement.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

abstract final class BookPdfContentRenderer {
  static List<pw.Widget> build({
    required List<BookExportBlock> blocks,
    required BookParagraphSettings settings,
    required Iterable<BookAsset> assets,
    double maxImageWidth = 450,
  }) {
    final output = <pw.Widget>[];
    var orderedIndex = 0;
    BookExportBlockType? previousType;

    for (final block in blocks) {
      if (block.type == BookExportBlockType.pageBreak) {
        output.add(pw.NewPage());
        previousType = block.type;
        continue;
      }
      if (block.type == BookExportBlockType.orderedListItem) {
        orderedIndex = previousType == BookExportBlockType.orderedListItem
            ? orderedIndex + 1
            : 1;
      } else {
        orderedIndex = 0;
      }
      output.addAll(
        _spacing(
          block,
          settings,
          _blockWidget(block, settings, orderedIndex, assets, maxImageWidth),
        ),
      );
      previousType = block.type;
    }
    return output;
  }

  static List<pw.Widget> _spacing(
    BookExportBlock block,
    BookParagraphSettings settings,
    pw.Widget child,
  ) {
    final isHeading = switch (block.type) {
      BookExportBlockType.heading1 ||
      BookExportBlockType.heading2 ||
      BookExportBlockType.heading3 => true,
      _ => false,
    };
    final before = isHeading
        ? settings.fontSizePt * 0.9
        : settings.spacingBeforePt;
    final after = isHeading
        ? settings.fontSizePt * 0.45
        : settings.spacingAfterPt;
    return [
      if (before > 0) pw.SizedBox(height: before),
      child,
      if (after > 0) pw.SizedBox(height: after),
    ];
  }

  static pw.Widget _blockWidget(
    BookExportBlock block,
    BookParagraphSettings settings,
    int orderedIndex,
    Iterable<BookAsset> assets,
    double maxImageWidth,
  ) {
    if (block.type == BookExportBlockType.image) {
      final asset = assets
          .where((candidate) => candidate.id == block.assetId)
          .firstOrNull;
      if (asset == null) return pw.SizedBox();
      return pw.Align(
        alignment: switch (block.imageAlignment) {
          BookImageAlignment.left => pw.Alignment.centerLeft,
          BookImageAlignment.center => pw.Alignment.center,
          BookImageAlignment.right => pw.Alignment.centerRight,
        },
        child: pw.SizedBox(
          width: maxImageWidth * block.imageWidthPercent / 100,
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Image(
                pw.MemoryImage(asset.bytes),
                height: 320,
                fit: pw.BoxFit.contain,
              ),
              if (block.imageCaption.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  block.imageCaption,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    final fontSize = switch (block.type) {
      BookExportBlockType.heading1 => settings.fontSizePt * 1.65,
      BookExportBlockType.heading2 => settings.fontSizePt * 1.4,
      BookExportBlockType.heading3 => settings.fontSizePt * 1.2,
      _ => settings.fontSizePt,
    };
    final text = _richText(
      block,
      settings,
      fontSize: fontSize,
      forceBold: switch (block.type) {
        BookExportBlockType.heading1 ||
        BookExportBlockType.heading2 ||
        BookExportBlockType.heading3 => true,
        _ => false,
      },
    );

    return switch (block.type) {
      BookExportBlockType.quote => pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(10, 4, 4, 4),
        margin: const pw.EdgeInsets.symmetric(vertical: 3),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: PdfColors.grey500, width: 2),
          ),
        ),
        child: text,
      ),
      BookExportBlockType.code => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(8),
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        child: text,
      ),
      BookExportBlockType.orderedListItem => _listRow(
        block,
        '$orderedIndex.',
        text,
      ),
      BookExportBlockType.bulletListItem => _listRow(block, '•', text),
      BookExportBlockType.checkedListItem => _checkRow(block, true, text),
      BookExportBlockType.uncheckedListItem => _checkRow(block, false, text),
      BookExportBlockType.image => pw.SizedBox(),
      BookExportBlockType.pageBreak => pw.SizedBox(),
      _ => text,
    };
  }

  static pw.Widget _richText(
    BookExportBlock block,
    BookParagraphSettings settings, {
    required double fontSize,
    required bool forceBold,
  }) {
    final spans = <pw.InlineSpan>[];
    final firstLineIndent = block.type == BookExportBlockType.paragraph
        ? settings.paragraphIndentMm
        : 0.0;
    final indentSpaces = (firstLineIndent / 1.8).round().clamp(0, 20);
    if (indentSpaces > 0) {
      spans.add(pw.TextSpan(text: List.filled(indentSpaces, '\u00A0').join()));
    }
    if (block.runs.isEmpty) {
      spans.add(const pw.TextSpan(text: ' '));
    } else {
      spans.addAll(
        block.runs.map(
          (run) => pw.TextSpan(
            text: run.text,
            baseline: run.superscript
                ? 3
                : run.subscript
                ? -2
                : 0,
            annotation: run.link == null ? null : pw.AnnotationUrl(run.link!),
            style: pw.TextStyle(
              fontSize:
                  run.fontSizePt ??
                  (run.superscript || run.subscript
                      ? fontSize * 0.75
                      : fontSize),
              fontWeight: forceBold || run.bold
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              fontStyle: run.italic ? pw.FontStyle.italic : pw.FontStyle.normal,
              color: run.link == null ? PdfColors.black : PdfColors.blue700,
              decoration: _decoration(run),
              background: run.code
                  ? const pw.BoxDecoration(color: PdfColors.grey200)
                  : null,
            ),
          ),
        ),
      );
    }
    final lineHeight = block.lineHeight ?? settings.lineHeight;
    return pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(
          fontSize: fontSize,
          lineSpacing: fontSize * (lineHeight - 1),
        ),
        children: spans,
      ),
      textAlign: _alignment(block.alignment),
      textDirection: block.rightToLeft
          ? pw.TextDirection.rtl
          : pw.TextDirection.ltr,
    );
  }

  static pw.Widget _listRow(
    BookExportBlock block,
    String marker,
    pw.Widget text,
  ) => pw.Padding(
    padding: pw.EdgeInsets.only(left: 12.0 + block.indent * 14.0),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 20, child: pw.Text(marker)),
        pw.Expanded(child: text),
      ],
    ),
  );

  static pw.Widget _checkRow(
    BookExportBlock block,
    bool checked,
    pw.Widget text,
  ) => pw.Padding(
    padding: pw.EdgeInsets.only(left: 12.0 + block.indent * 14.0),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 2, right: 11),
          child: pw.CustomPaint(
            size: const PdfPoint(9, 9),
            painter: (canvas, size) {
              canvas
                ..setStrokeColor(PdfColors.black)
                ..setLineWidth(0.8)
                ..drawRect(0, 0, size.x, size.y)
                ..strokePath();
              if (checked) {
                canvas
                  ..setLineWidth(1.15)
                  ..moveTo(1.6, size.y * 0.48)
                  ..lineTo(size.x * 0.42, 1.8)
                  ..lineTo(size.x - 1.4, size.y - 1.7)
                  ..strokePath();
              }
            },
          ),
        ),
        pw.Expanded(child: text),
      ],
    ),
  );

  static pw.TextDecoration? _decoration(BookExportTextRun run) {
    final values = <pw.TextDecoration>[
      if (run.underline) pw.TextDecoration.underline,
      if (run.strike) pw.TextDecoration.lineThrough,
    ];
    if (values.isEmpty) return null;
    return pw.TextDecoration.combine(values);
  }

  static pw.TextAlign _alignment(BookExportTextAlignment alignment) =>
      switch (alignment) {
        BookExportTextAlignment.left => pw.TextAlign.left,
        BookExportTextAlignment.center => pw.TextAlign.center,
        BookExportTextAlignment.right => pw.TextAlign.right,
        BookExportTextAlignment.justify => pw.TextAlign.justify,
      };
}
