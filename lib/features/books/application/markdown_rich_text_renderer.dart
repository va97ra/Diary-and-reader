import 'package:dnevnik/features/books/application/book_export_content.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';

abstract final class MarkdownRichTextRenderer {
  static String render(RichDocument document) {
    final output = StringBuffer();
    var orderedIndex = 0;
    for (final block in BookExportContentParser.parse(document)) {
      if (block.type != BookExportBlockType.orderedListItem) orderedIndex = 0;
      final content = block.runs.map(_inline).join();
      if (block.semanticStyle == 'sceneBreak') {
        output.writeln('---\n');
        continue;
      }
      switch (block.type) {
        case BookExportBlockType.heading1:
          output.writeln('### $content\n');
          break;
        case BookExportBlockType.heading2:
          output.writeln('#### $content\n');
          break;
        case BookExportBlockType.heading3:
          output.writeln('##### $content\n');
          break;
        case BookExportBlockType.quote:
          output.writeln('> $content\n');
          break;
        case BookExportBlockType.code:
          output.writeln('~~~\n${_plain(block)}\n~~~\n');
          break;
        case BookExportBlockType.orderedListItem:
          orderedIndex++;
          output.writeln('$orderedIndex. $content');
          break;
        case BookExportBlockType.bulletListItem:
          output.writeln('- $content');
          break;
        case BookExportBlockType.checkedListItem:
          output.writeln('- [x] $content');
          break;
        case BookExportBlockType.uncheckedListItem:
          output.writeln('- [ ] $content');
          break;
        case BookExportBlockType.paragraph:
          output.writeln('$content\n');
          break;
      }
    }
    return output.toString().trimRight();
  }

  static String _inline(BookExportTextRun run) {
    var text = run.code ? _code(run.text) : _escape(run.text);
    if (run.bold) text = '**$text**';
    if (run.italic) text = '*$text*';
    if (run.underline) text = '<u>$text</u>';
    if (run.strike) text = '~~$text~~';
    if (run.superscript) text = '<sup>$text</sup>';
    if (run.subscript) text = '<sub>$text</sub>';
    if (run.link != null) text = '[$text](${run.link})';
    return text;
  }

  static String _plain(BookExportBlock block) =>
      block.runs.map((run) => run.text).join();

  static String _code(String value) {
    final fence = value.contains('`') ? '``' : '`';
    return '$fence$value$fence';
  }

  static String _escape(String value) => value.replaceAllMapped(
    RegExp(r'[\\`*{}\[\]()_>#+.!|~-]'),
    (match) => '\\${match.group(0)}',
  );
}
