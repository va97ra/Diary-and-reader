import 'package:dnevnik/features/books/application/book_export_content.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';

abstract final class PlainTextRichRenderer {
  static String render(RichDocument document) {
    final output = StringBuffer();
    var orderedIndex = 0;
    for (final block in BookExportContentParser.parse(document)) {
      if (block.type != BookExportBlockType.orderedListItem) orderedIndex = 0;
      final text = block.runs.map((run) => run.text).join();
      switch (block.type) {
        case BookExportBlockType.heading1 ||
            BookExportBlockType.heading2 ||
            BookExportBlockType.heading3:
          output.writeln(text.toUpperCase());
          break;
        case BookExportBlockType.quote:
          output.writeln('> $text');
          break;
        case BookExportBlockType.orderedListItem:
          orderedIndex++;
          output.writeln('$orderedIndex. $text');
          break;
        case BookExportBlockType.bulletListItem:
          output.writeln('• $text');
          break;
        case BookExportBlockType.checkedListItem:
          output.writeln('[x] $text');
          break;
        case BookExportBlockType.uncheckedListItem:
          output.writeln('[ ] $text');
          break;
        case BookExportBlockType.code || BookExportBlockType.paragraph:
          output.writeln(text);
          break;
      }
    }
    return output.toString().trimRight();
  }
}
