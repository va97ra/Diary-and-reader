import 'package:dnevnik/features/books/application/book_image_document_editing.dart';
import 'package:dnevnik/features/books/domain/book_image_placement.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const image = BookImagePlacement(assetId: 'image-1');

  QuillController controllerFor(List<Map<String, dynamic>> ops) =>
      QuillController(
        document: Document.fromJson(ops),
        selection: const TextSelection.collapsed(offset: 0),
      );

  String layout(QuillController controller) => controller.document
      .toPlainText()
      .replaceAll(Embed.kObjectReplacementCharacter, '[I]');

  test('inserts an illustration on its own line in the middle of text', () {
    final controller = controllerFor([
      {'insert': 'Hello\n'},
    ]);

    final offset = BookImageDocumentEditing.insert(controller, 2, image);

    expect(layout(controller), 'He\n[I]\nllo\n');
    expect(offset, 3);
    expect(
      BookImageDocumentEditing.placementAt(controller, 3)?.assetId,
      'image-1',
    );
    expect(BookImageDocumentEditing.placementAt(controller, 0), isNull);
  });

  test('inserting at the end of a paragraph adds no blank line', () {
    final controller = controllerFor([
      {'insert': 'One\nTwo\n'},
    ]);

    final offset = BookImageDocumentEditing.insert(controller, 3, image);

    expect(layout(controller), 'One\n[I]\nTwo\n');
    expect(offset, 4);
    expect(controller.selection.baseOffset, 6);
  });

  test('replaces placement data in place', () {
    final controller = controllerFor([
      {'insert': 'A\n'},
    ]);
    final offset = BookImageDocumentEditing.insert(controller, 2, image);

    BookImageDocumentEditing.replace(
      controller,
      offset,
      image.copyWith(widthPercent: 40, alignment: BookImageAlignment.left),
    );

    final placement = BookImageDocumentEditing.placementAt(controller, offset);
    expect(placement?.widthPercent, 40);
    expect(placement?.alignment, BookImageAlignment.left);
    expect(layout(controller), 'A\n[I]\n\n');
  });

  test('removes the illustration line without leaving a blank paragraph', () {
    final controller = controllerFor([
      {'insert': 'One\n'},
      {
        'insert': {'bookImage': image.encode()},
      },
      {'insert': '\nTwo\n'},
    ]);

    expect(BookImageDocumentEditing.remove(controller, 4), isTrue);
    expect(layout(controller), 'One\nTwo\n');
    expect(BookImageDocumentEditing.remove(controller, 0), isFalse);
  });

  test('moves an illustration up and down between paragraphs', () {
    final controller = controllerFor([
      {'insert': 'One\nTwo\n'},
      {
        'insert': {'bookImage': image.encode()},
      },
      {'insert': '\nThree\n'},
    ]);

    final up = BookImageDocumentEditing.move(controller, 8, 0);
    expect(layout(controller), '[I]\nOne\nTwo\nThree\n');
    expect(up, 0);

    final down = BookImageDocumentEditing.move(controller, 0, 16);
    expect(layout(controller), 'One\nTwo\nThree\n[I]\n\n');
    expect(down, 14);
    expect(
      BookImageDocumentEditing.placementAt(controller, 14)?.assetId,
      'image-1',
    );
  });

  test('moving onto its own line is a no-op and undo restores a move', () {
    final controller = controllerFor([
      {'insert': 'One\n'},
      {
        'insert': {'bookImage': image.encode()},
      },
      {'insert': '\nTwo\n'},
    ]);

    expect(BookImageDocumentEditing.move(controller, 4, 4), isNull);
    expect(BookImageDocumentEditing.move(controller, 4, 6), isNull);

    BookImageDocumentEditing.move(controller, 4, 0);
    expect(layout(controller), '[I]\nOne\nTwo\n');
    controller.undo();
    expect(layout(controller), 'One\n[I]\nTwo\n');
  });

  test('reads legacy custom embed payloads', () {
    final controller = controllerFor([
      {
        'insert': {'custom': '{"bookImage":"{\\"assetId\\":\\"old\\"}"}'},
      },
      {'insert': '\n'},
    ]);

    expect(BookImageDocumentEditing.placementAt(controller, 0)?.assetId, 'old');
  });
}
