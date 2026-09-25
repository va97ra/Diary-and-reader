import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_docx_exporter.dart';
import 'package:dnevnik/features/books/application/book_export_content.dart';
import 'package:dnevnik/features/books/application/book_pdf_content_renderer.dart';
import 'package:dnevnik/features/books/application/epub_rich_text_renderer.dart';
import 'package:dnevnik/features/books/application/fb2_rich_text_renderer.dart';
import 'package:dnevnik/features/books/application/markdown_rich_text_renderer.dart';
import 'package:dnevnik/features/books/application/plain_text_rich_renderer.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter_test/flutter_test.dart';

const _verse = {
  'blockquote': true,
  'align': 'center',
  'bookParagraphStyle': 'verse',
};

/// Two stanzas between prose, and one red word.
const RichDocument _poem = [
  {'insert': 'Before.\n'},
  {'insert': 'First line'},
  {'insert': '\n', 'attributes': _verse},
  {'insert': 'Second line'},
  {'insert': '\n', 'attributes': _verse},
  {'insert': '\n', 'attributes': _verse},
  {'insert': 'Third line'},
  {'insert': '\n', 'attributes': _verse},
  {'insert': 'After '},
  {
    'insert': 'red',
    'attributes': {'color': '#c62828'},
  },
  {'insert': '.\n'},
];

void main() {
  test('export blocks keep verse lines and word colours', () {
    final blocks = BookExportContentParser.parse(_poem);

    expect(blocks.where((block) => block.isVerse), hasLength(4));
    final red = blocks.last.runs.singleWhere((run) => run.text == 'red');
    expect(red.colorHex, 'C62828');
  });

  test('EPUB gathers a poem and colours the word', () {
    final html = EpubRichTextRenderer.render(_poem);

    expect('<div class="poem">'.allMatches(html), hasLength(1));
    final poem = html.substring(
      html.indexOf('<div class="poem">'),
      html.indexOf('</div>'),
    );
    expect(poem, contains('First line</p>'));
    expect(poem, contains('&#160;</p>'));
    expect(poem, contains('Third line</p>'));
    expect(poem, contains('class="align-center verse"'));
    expect(poem, isNot(contains('After')));
    expect(html, contains('<span style="color:#C62828">red</span>'));
  });

  test('FB2 writes a poem with a stanza per group of lines', () {
    final xml = Fb2RichTextRenderer.render(_poem);

    expect('<poem>'.allMatches(xml), hasLength(1));
    expect('<stanza>'.allMatches(xml), hasLength(2));
    expect(xml, contains('<v>First line</v>'));
    expect(xml, contains('<v>Third line</v>'));
    expect(xml.indexOf('</poem>'), lessThan(xml.indexOf('After')));
  });

  test('Markdown and plain text keep stanzas compact', () {
    final newline = String.fromCharCode(10);
    final markdown = MarkdownRichTextRenderer.render(_poem);
    expect(
      markdown,
      contains('First line  ${newline}Second line$newline${newline}Third line'),
    );

    final text = PlainTextRichRenderer.render(_poem);
    expect(
      text,
      contains('First line${newline}Second line$newline${newline}Third line'),
    );
    expect(text, isNot(contains('> First')));
  });

  test('DOCX gives verse its own style and keeps the colour', () {
    final chapter = BookProject.create(
      title: 'Стихи',
      chapterTitle: 'Глава',
      languageCode: 'ru',
    );
    final project = chapter.copyWith(
      sections: [chapter.sections.single.copyWith(content: _poem)],
    );

    final archive = ZipDecoder().decodeBytes(
      BookDocxExporter.create(project).bytes,
    );
    String file(String name) =>
        utf8.decode(archive.files.singleWhere((f) => f.name == name).content);
    final document = file('word/document.xml');
    final styles = file('word/styles.xml');

    expect('<w:pStyle w:val="BookVerse"/>'.allMatches(document), hasLength(4));
    expect(styles, contains('w:styleId="BookVerse"'));
    expect(styles, contains('<w:contextualSpacing/>'));
    expect(document, contains('<w:color w:val="C62828"/>'));
  });

  test('PDF lays verse out without failing', () {
    final widgets = BookPdfContentRenderer.build(
      blocks: BookExportContentParser.parse(_poem),
      settings: const BookParagraphSettings(),
      assets: const [],
    );

    expect(widgets, isNotEmpty);
  });
}
