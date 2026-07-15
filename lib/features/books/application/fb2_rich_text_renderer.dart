import 'package:dnevnik/features/books/application/book_export_content.dart';
import 'package:dnevnik/features/books/application/epub_rich_text_renderer.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';

abstract final class Fb2RichTextRenderer {
  static String render(RichDocument document) {
    final output = StringBuffer();
    var orderedIndex = 0;
    for (final block in BookExportContentParser.parse(document)) {
      if (block.type != BookExportBlockType.orderedListItem) orderedIndex = 0;
      if (block.runs.isEmpty) {
        output.writeln('      <empty-line/>');
        continue;
      }
      final content = block.runs.map(_inline).join();
      switch (block.type) {
        case BookExportBlockType.heading1 ||
            BookExportBlockType.heading2 ||
            BookExportBlockType.heading3:
          output.writeln('      <subtitle>$content</subtitle>');
          break;
        case BookExportBlockType.quote:
          output.writeln('      <cite><p>$content</p></cite>');
          break;
        case BookExportBlockType.code:
          output.writeln('      <p><code>$content</code></p>');
          break;
        case BookExportBlockType.orderedListItem:
          orderedIndex++;
          output.writeln('      <p>$orderedIndex. $content</p>');
          break;
        case BookExportBlockType.bulletListItem:
          output.writeln('      <p>• $content</p>');
          break;
        case BookExportBlockType.checkedListItem:
          output.writeln('      <p>☑ $content</p>');
          break;
        case BookExportBlockType.uncheckedListItem:
          output.writeln('      <p>☐ $content</p>');
          break;
        case BookExportBlockType.paragraph:
          if (block.semanticStyle == 'sceneBreak') {
            output.writeln('      <empty-line/>');
          } else {
            output.writeln('      <p>$content</p>');
          }
          break;
      }
    }
    return output.toString();
  }

  static String _inline(BookExportTextRun run) {
    var xml = escapeXml(run.text);
    if (run.code) xml = '<code>$xml</code>';
    if (run.bold) xml = '<strong>$xml</strong>';
    if (run.italic) xml = '<emphasis>$xml</emphasis>';
    if (run.strike) xml = '<strikethrough>$xml</strikethrough>';
    if (run.superscript) xml = '<sup>$xml</sup>';
    if (run.subscript) xml = '<sub>$xml</sub>';
    if (run.link != null) {
      xml = '<a l:type="simple" l:href="${escapeXml(run.link!)}">$xml</a>';
    }
    return xml;
  }
}
