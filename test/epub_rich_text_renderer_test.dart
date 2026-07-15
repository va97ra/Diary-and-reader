import 'package:dnevnik/features/books/application/epub_rich_text_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renders supported inline and block semantics as safe XHTML', () {
    final html = EpubRichTextRenderer.render(const [
      {
        'insert': '<текст>',
        'attributes': {'italic': true, 'underline': true},
      },
      {
        'insert': '\n',
        'attributes': {
          'blockquote': true,
          'align': 'right',
          'bookParagraphStyle': 'epigraph',
        },
      },
      {
        'insert': 'опасная ссылка',
        'attributes': {'link': 'javascript:alert(1)'},
      },
      {'insert': '\n'},
      {
        'insert': 'код',
        'attributes': {'code': true},
      },
      {
        'insert': '\n',
        'attributes': {'code-block': true},
      },
    ]);

    expect(html, contains('<blockquote class="align-right epigraph">'));
    expect(html, contains('<u><em>&lt;текст&gt;</em></u>'));
    expect(html, isNot(contains('javascript:')));
    expect(html, contains('<pre><code>код</code></pre>'));
  });
}
