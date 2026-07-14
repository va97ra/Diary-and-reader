import 'package:dnevnik/features/books/domain/book_paragraph_style.dart';
import 'package:dnevnik/features/books/presentation/book_paragraph_style_actions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies and replaces semantic paragraph styles', () {
    final controller = QuillController(
      document: Document.fromJson([
        {'insert': 'Заголовок\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 3),
    );
    addTearDown(controller.dispose);

    BookParagraphStyleActions.apply(controller, BookParagraphStyle.heading1);
    expect(
      BookParagraphStyleActions.current(controller),
      BookParagraphStyle.heading1,
    );
    expect(_lineAttributes(controller)['header'], 1);
    expect(
      _lineAttributes(
        controller,
      )[BookParagraphStyleActions.semanticAttributeKey],
      BookParagraphStyle.heading1.name,
    );

    BookParagraphStyleActions.apply(controller, BookParagraphStyle.epigraph);
    expect(
      BookParagraphStyleActions.current(controller),
      BookParagraphStyle.epigraph,
    );
    expect(_lineAttributes(controller)['header'], isNull);
    expect(_lineAttributes(controller)['blockquote'], isTrue);
    expect(_lineAttributes(controller)['align'], 'right');
    expect(
      _lineAttributes(
        controller,
      )[BookParagraphStyleActions.semanticAttributeKey],
      BookParagraphStyle.epigraph.name,
    );

    BookParagraphStyleActions.apply(controller, BookParagraphStyle.body);
    expect(
      BookParagraphStyleActions.current(controller),
      BookParagraphStyle.body,
    );
    expect(_lineAttributes(controller)['blockquote'], isNull);
    expect(_lineAttributes(controller)['align'], isNull);
    expect(
      _lineAttributes(
        controller,
      )[BookParagraphStyleActions.semanticAttributeKey],
      BookParagraphStyle.body.name,
    );
  });

  test('inserts and marks a scene divider on an empty line', () {
    final controller = QuillController(
      document: Document.fromJson([
        {'insert': 'Первый абзац\n\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 13),
    );
    addTearDown(controller.dispose);

    BookParagraphStyleActions.apply(controller, BookParagraphStyle.sceneBreak);

    expect(controller.document.toPlainText(), contains('* * *'));
    expect(
      BookParagraphStyleActions.current(controller),
      BookParagraphStyle.sceneBreak,
    );
    final divider = controller.document.toDelta().toJson().where(
      (operation) =>
          operation['insert'] == '\n' &&
          (operation['attributes']
                  as Map?)?[BookParagraphStyleActions.semanticAttributeKey] ==
              BookParagraphStyle.sceneBreak.name,
    );
    expect(divider, hasLength(1));
    expect((divider.single['attributes'] as Map?)?['align'], 'center');
  });

  test('keeps semantic style after document serialization', () {
    final source = QuillController(
      document: Document.fromJson([
        {'insert': 'Цитата\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 2),
    );
    addTearDown(source.dispose);
    BookParagraphStyleActions.apply(source, BookParagraphStyle.epigraph);

    final restored = QuillController(
      document: Document.fromJson(source.document.toDelta().toJson()),
      selection: const TextSelection.collapsed(offset: 2),
    );
    addTearDown(restored.dispose);

    expect(
      BookParagraphStyleActions.current(restored),
      BookParagraphStyle.epigraph,
    );
    expect(
      _lineAttributes(restored)[BookParagraphStyleActions.semanticAttributeKey],
      BookParagraphStyle.epigraph.name,
    );
  });
}

Map<String, dynamic> _lineAttributes(QuillController controller) {
  final operation = controller.document.toDelta().toJson().firstWhere(
    (operation) => operation['insert'] == '\n',
  );
  return Map<String, dynamic>.from(operation['attributes'] as Map? ?? const {});
}
