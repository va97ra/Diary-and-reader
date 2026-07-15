import 'package:dnevnik/features/books/application/book_export_content.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';

abstract final class EpubRichTextRenderer {
  static String render(RichDocument document) {
    final blocks = BookExportContentParser.parse(document);
    final output = StringBuffer();
    String? openList;

    void closeList() {
      if (openList == null) return;
      output.writeln('</$openList>');
      openList = null;
    }

    for (final block in blocks) {
      final listTag = switch (block.type) {
        BookExportBlockType.orderedListItem => 'ol',
        BookExportBlockType.bulletListItem ||
        BookExportBlockType.checkedListItem ||
        BookExportBlockType.uncheckedListItem => 'ul',
        _ => null,
      };
      final content = block.runs.isEmpty
          ? '&#160;'
          : block.runs.map(_inline).join();
      if (listTag != null) {
        if (openList != listTag) {
          closeList();
          output.writeln('<$listTag>');
          openList = listTag;
        }
        final checkbox = switch (block.type) {
          BookExportBlockType.checkedListItem =>
            '<span class="check">☑</span> ',
          BookExportBlockType.uncheckedListItem =>
            '<span class="check">☐</span> ',
          _ => '',
        };
        output.writeln('<li${_blockAttributes(block)}>$checkbox$content</li>');
        continue;
      }

      closeList();
      final tag = switch (block.type) {
        BookExportBlockType.heading1 => 'h2',
        BookExportBlockType.heading2 => 'h3',
        BookExportBlockType.heading3 => 'h4',
        BookExportBlockType.quote => 'blockquote',
        BookExportBlockType.code => 'pre',
        _ => 'p',
      };
      output.writeln('<$tag${_blockAttributes(block)}>$content</$tag>');
    }
    closeList();
    return output.toString();
  }

  static String _inline(BookExportTextRun run) {
    var html = escapeXml(run.text);
    final styles = <String>[
      if (run.fontSizePt != null) 'font-size:${_number(run.fontSizePt!)}pt',
      if (run.fontFamily != null)
        'font-family:&quot;${escapeXml(run.fontFamily!)}&quot;',
    ];
    if (styles.isNotEmpty) {
      html = '<span style="${styles.join(';')}">$html</span>';
    }
    if (run.code) html = '<code>$html</code>';
    if (run.bold) html = '<strong>$html</strong>';
    if (run.italic) html = '<em>$html</em>';
    if (run.underline) html = '<u>$html</u>';
    if (run.strike) html = '<s>$html</s>';
    if (run.superscript) html = '<sup>$html</sup>';
    if (run.subscript) html = '<sub>$html</sub>';
    if (run.link != null) {
      html = '<a href="${escapeXml(run.link!)}">$html</a>';
    }
    return html;
  }

  static String _blockAttributes(BookExportBlock block) {
    final classes = <String>[
      if (block.alignment != BookExportTextAlignment.left)
        'align-${block.alignment.name}',
      if (block.indent > 0) 'indent-${block.indent}',
      if (block.semanticStyle == 'epigraph') 'epigraph',
      if (block.semanticStyle == 'sceneBreak') 'scene-break',
    ];
    final className = classes.isEmpty ? '' : ' class="${classes.join(' ')}"';
    final direction = block.rightToLeft ? ' dir="rtl"' : '';
    final style = block.lineHeight == null
        ? ''
        : ' style="line-height:${_number(block.lineHeight!)}"';
    return '$className$direction$style';
  }

  static String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

String escapeXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
