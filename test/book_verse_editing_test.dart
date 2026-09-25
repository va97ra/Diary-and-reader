import 'package:dnevnik/features/books/presentation/book_paragraph_style_actions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

const _verse = {
  'blockquote': true,
  'align': 'center',
  'bookParagraphStyle': 'verse',
};

QuillController _editor(List<Map<String, dynamic>> operations) {
  final document = Document.fromJson(operations)
    ..setCustomRules(const [BookQuoteBlockExitRule()]);
  return QuillController(
    document: document,
    selection: const TextSelection.collapsed(offset: 0),
  );
}

/// Presses Enter at the end of the text before the last line break.
void _enter(QuillController controller) {
  final at = controller.document.length - 1;
  controller.replaceText(at, 0, '\n', TextSelection.collapsed(offset: at + 1));
}

/// Each line's text with the attributes of its line break.
List<List<Object?>> _lines(QuillController controller) {
  final lines = <List<Object?>>[];
  var text = '';
  for (final operation in controller.document.toDelta().toList()) {
    final data = operation.data;
    if (data is! String) {
      text += '[embed]';
      continue;
    }
    final parts = data.split('\n');
    for (var index = 0; index < parts.length - 1; index++) {
      lines.add([text + parts[index], operation.attributes]);
      text = '';
    }
    text += parts.last;
  }
  return lines;
}

void main() {
  test('one empty line in a poem separates stanzas and the poem goes on', () {
    final controller = _editor([
      {'insert': 'First line'},
      {'insert': '\n', 'attributes': _verse},
      {'insert': 'Second line'},
      {'insert': '\n', 'attributes': _verse},
    ]);

    _enter(controller);
    _enter(controller);
    controller.replaceText(
      controller.document.length - 1,
      0,
      'Third line',
      null,
    );

    expect(_lines(controller), [
      ['First line', _verse],
      ['Second line', _verse],
      ['', _verse],
      ['Third line', _verse],
    ]);
  });

  test('a second empty line leaves the poem for plain text', () {
    final controller = _editor([
      {'insert': 'Last line'},
      {'insert': '\n', 'attributes': _verse},
    ]);

    _enter(controller); // an empty line in the poem
    _enter(controller); // a stanza break
    _enter(controller); // the poem is over

    expect(_lines(controller), [
      ['Last line', _verse],
      ['', _verse],
      ['', null],
    ]);
  });

  test('an empty line of a quote turns into plain text, name and all', () {
    final controller = _editor([
      {'insert': 'Quoted'},
      {
        'insert': '\n',
        'attributes': {'blockquote': true, 'bookParagraphStyle': 'quote'},
      },
    ]);

    _enter(controller);
    _enter(controller);

    expect(_lines(controller), [
      [
        'Quoted',
        {'blockquote': true, 'bookParagraphStyle': 'quote'},
      ],
      ['', null],
    ]);
  });

  test('lines that lost the quote mark of their poem get it back', () {
    final broken = [
      {'insert': 'Den chudesnyj'},
      {
        'insert': '\n',
        'attributes': {'align': 'center', 'bookParagraphStyle': 'verse'},
      },
      {'insert': 'Plain'},
      {
        'insert': '\n',
        'attributes': {'align': 'center'},
      },
    ];

    final repaired = BookParagraphStyleActions.repairQuoteBlocks(broken);

    expect(repaired[1]['attributes'], _verse);
    expect(repaired[3]['attributes'], {'align': 'center'});
    final intact = [
      {'insert': 'Line'},
      {'insert': '\n', 'attributes': _verse},
    ];
    expect(BookParagraphStyleActions.repairQuoteBlocks(intact), same(intact));
  });
}
