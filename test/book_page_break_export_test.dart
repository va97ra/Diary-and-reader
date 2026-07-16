import 'package:dnevnik/features/books/application/book_export_content.dart';
import 'package:dnevnik/features/books/application/book_pdf_content_renderer.dart';
import 'package:dnevnik/features/books/application/epub_rich_text_renderer.dart';
import 'package:dnevnik/features/books/application/fb2_rich_text_renderer.dart';
import 'package:dnevnik/features/books/application/markdown_rich_text_renderer.dart';
import 'package:dnevnik/features/books/application/plain_text_rich_renderer.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  const document = [
    {'insert': 'До\n'},
    {
      'insert': {'custom': '{"bookPageBreak":"1"}'},
    },
    {'insert': '\nПосле\n'},
  ];

  test('parses a page break without creating an empty paragraph', () {
    final blocks = BookExportContentParser.parse(document);

    expect(blocks.map((block) => block.type), [
      BookExportBlockType.paragraph,
      BookExportBlockType.pageBreak,
      BookExportBlockType.paragraph,
    ]);
  });

  test('preserves page breaks in ebook and text-oriented exports', () {
    expect(
      EpubRichTextRenderer.render(document),
      contains('class="page-break"'),
    );
    expect(Fb2RichTextRenderer.render(document), contains('<empty-line/>'));
    expect(
      MarkdownRichTextRenderer.render(document),
      contains('break-after: page'),
    );
    expect(PlainTextRichRenderer.render(document), contains('\f'));
  });

  test('turns a manuscript page break into a PDF page boundary', () {
    final widgets = BookPdfContentRenderer.build(
      blocks: BookExportContentParser.parse(document),
      settings: const BookParagraphSettings(),
      assets: const [],
    );

    expect(widgets.whereType<pw.NewPage>(), hasLength(1));
  });
}
