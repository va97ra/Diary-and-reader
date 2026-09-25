import 'dart:convert';

import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_image_file.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_image_placement.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/literia_test_navigation.dart';
import 'support/memory_author_workspace_repository.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

const _image = ValueKey('book-image-action-image-1');
const _toolbar = ValueKey('image-inline-toolbar');

Future<AuthorWorkspaceController> _projectWithImage({
  BookImageAlignment alignment = BookImageAlignment.center,
  int widthPercent = 50,
}) async {
  final controller = AuthorWorkspaceController(
    MemoryAuthorWorkspaceRepository(),
  );
  await controller.load(preferredLanguage: 'ru');
  controller.addAsset(
    BookAsset(id: 'image-1', mediaType: 'image/png', bytes: _png),
  );
  controller.updateSectionContent([
    {'insert': 'Первый абзац.\n'},
    {
      'insert': {
        'bookImage': BookImagePlacement(
          assetId: 'image-1',
          widthPercent: widthPercent,
          alignment: alignment,
        ).encode(),
      },
    },
    {'insert': '\nВторой абзац.\nТретий абзац.\n'},
  ]);
  return controller;
}

List<BookImagePlacement> _placements(AuthorWorkspaceController controller) => [
  for (final operation in controller.activeSection!.content)
    if (operation['insert'] case final Map insert)
      BookImagePlacement.decode(
        (insert['bookImage'] ??
                jsonDecode(insert['custom'] as String)['bookImage'])
            as String,
      ),
];

/// The section text with each illustration shown as `[I]`.
String _layout(AuthorWorkspaceController controller) => controller
    .activeSection!
    .content
    .map(
      (operation) => operation['insert'] is Map ? '[I]' : operation['insert'],
    )
    .join();

Future<void> _open(
  WidgetTester tester,
  AuthorWorkspaceController controller, {
  BookClipboardImageGateway? clipboard,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    AuthorStudioApp(
      controller: controller,
      clipboardImageGateway: clipboard ?? _MemoryClipboard(null),
    ),
  );
  await tester.pumpAndSettle();
  await openLastManuscript(tester, controller);
}

QuillController _editorController(WidgetTester tester) =>
    tester.widget<QuillEditor>(find.byType(QuillEditor)).controller;

void main() {
  testWidgets('tapping an illustration selects it without the keyboard', (
    tester,
  ) async {
    final controller = await _projectWithImage();
    await _open(tester, controller);

    await tester.tap(find.byKey(_image));
    await tester.pumpAndSettle();

    expect(find.byKey(_toolbar), findsOneWidget);
    expect(find.byKey(const ValueKey('image-inline-size')), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(tester.testTextInput.isVisible, isFalse);

    // Moving the cursor into the text drops the selection.
    _editorController(tester).updateSelection(
      const TextSelection.collapsed(offset: 2),
      ChangeSource.local,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(_toolbar), findsNothing);
  });

  testWidgets('a full-width picture moves to the side it is aligned to', (
    tester,
  ) async {
    final controller = await _projectWithImage(widthPercent: 100);
    await _open(tester, controller);
    await tester.tap(find.byKey(_image));
    await tester.pumpAndSettle();
    final page = tester.getRect(find.byKey(_image));

    await tester.tap(find.byKey(const ValueKey('image-align-left')));
    await tester.pumpAndSettle();
    expect(_placements(controller).single.alignment, BookImageAlignment.left);
    expect(_placements(controller).single.widthPercent, 75);
    final left = tester.getRect(find.byKey(_image));
    expect(left.left, moreOrLessEquals(page.left));
    expect(left.width, moreOrLessEquals(page.width * 0.75));

    await tester.tap(find.byKey(const ValueKey('image-align-right')));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(_image)).right,
      moreOrLessEquals(page.right),
    );
  });

  testWidgets('inline tools align, resize, and delete into the trash', (
    tester,
  ) async {
    final controller = await _projectWithImage();
    await _open(tester, controller);
    await tester.tap(find.byKey(_image));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('image-align-right')));
    await tester.pumpAndSettle();
    expect(_placements(controller).single.alignment, BookImageAlignment.right);
    expect(find.byKey(_toolbar), findsOneWidget, reason: 'stays selected');

    await tester.tap(find.byKey(const ValueKey('image-larger')));
    await tester.pumpAndSettle();
    expect(_placements(controller).single.widthPercent, 60);
    await tester.tap(find.byKey(const ValueKey('image-smaller')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('image-smaller')));
    await tester.pumpAndSettle();
    expect(_placements(controller).single.widthPercent, 40);

    await tester.tap(find.byKey(const ValueKey('image-inline-delete')));
    await tester.pumpAndSettle();
    expect(_placements(controller), isEmpty);
    expect(
      _layout(controller),
      'Первый абзац.\nВторой абзац.\nТретий абзац.\n',
    );
    // The picture waits in the trash instead of an undo bar.
    expect(find.byType(SnackBar), findsNothing);
    final entry = controller.activeProject!.textTrash.single;
    expect(entry.hasEmbed, isTrue);

    controller.restoreDeletedText(entry.id);
    await tester.pumpAndSettle();
    expect(_placements(controller), hasLength(1));
  });

  testWidgets('dragging a corner handle resizes the illustration', (
    tester,
  ) async {
    final controller = await _projectWithImage();
    await _open(tester, controller);
    await tester.tap(find.byKey(_image));
    await tester.pumpAndSettle();

    final handle = find.byKey(const ValueKey('image-resize-handle-1.0-1.0'));
    expect(handle, findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(20, 0));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(find.byKey(const ValueKey('image-resize-badge')), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();

    // A centred image grows on both sides: 60 px on each side of a 350 px
    // row adds about 34 percentage points.
    expect(
      _placements(controller).single.widthPercent,
      inInclusiveRange(80, 88),
    );
    expect(find.byKey(const ValueKey('image-resize-badge')), findsNothing);
  });

  testWidgets('long press drags the illustration to another paragraph', (
    tester,
  ) async {
    final controller = await _projectWithImage();
    await _open(tester, controller);

    final third = find.textContaining('Третий абзац', findRichText: true);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_image)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getBottomLeft(third) + const Offset(40, -2));
    await tester.pump();
    expect(find.byKey(const ValueKey('image-drop-indicator')), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      _layout(controller),
      'Первый абзац.\nВторой абзац.\nТретий абзац.\n[I]\n\n',
    );
    expect(find.byKey(const ValueKey('image-drop-indicator')), findsNothing);
    expect(find.byKey(_toolbar), findsOneWidget, reason: 'stays selected');

    _editorController(tester).undo();
    await tester.pumpAndSettle();
    expect(_layout(controller), startsWith('Первый абзац.\n'));
    expect(_layout(controller), contains('[I]\nВторой абзац.'));
  });

  testWidgets('pastes a clipboard picture from the picture sheet', (
    tester,
  ) async {
    final controller = await _projectWithImage();
    final clipboard = _MemoryClipboard(
      BookImageFile(name: 'copied.png', bytes: _png),
    );
    await _open(tester, controller, clipboard: clipboard);
    _editorController(tester).updateSelection(
      const TextSelection.collapsed(offset: 'Первый абзац.'.length),
      ChangeSource.local,
    );

    await tester.tap(find.byKey(const ValueKey('writer-picture-action')));
    await tester.pumpAndSettle();
    expect(find.text('Из галереи'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-picture-from-clipboard')));
    await tester.pumpAndSettle();

    expect(clipboard.readCount, 1);
    expect(controller.activeProject!.assets, hasLength(2));
    expect(_placements(controller), hasLength(2));
    expect(_layout(controller), startsWith('Первый абзац.\n[I]\n'));
    expect(find.text('Изображение добавлено в рукопись'), findsOneWidget);
  });

  testWidgets('reports an empty clipboard instead of pasting nothing', (
    tester,
  ) async {
    final controller = await _projectWithImage();
    await _open(tester, controller);

    await tester.tap(find.byKey(const ValueKey('writer-picture-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-picture-from-clipboard')));
    await tester.pumpAndSettle();

    expect(_placements(controller), hasLength(1));
    expect(find.textContaining('В буфере обмена нет картинки'), findsOneWidget);
  });

  testWidgets('the paste command inserts a picture when there is no text', (
    tester,
  ) async {
    final controller = await _projectWithImage();
    final clipboard = _MemoryClipboard(
      BookImageFile(name: 'copied.png', bytes: _png),
    );
    await _open(tester, controller, clipboard: clipboard);
    final editor = _editorController(tester);
    editor.updateSelection(
      TextSelection.collapsed(offset: editor.document.length - 1),
      ChangeSource.local,
    );

    // ignore: experimental_member_use
    await tester.runAsync(editor.clipboardPaste);
    await tester.pumpAndSettle();

    expect(clipboard.readCount, 1);
    expect(_placements(controller), hasLength(2));
  });
}

class _MemoryClipboard implements BookClipboardImageGateway {
  _MemoryClipboard(this.file);

  final BookImageFile? file;
  int readCount = 0;

  @override
  Future<bool> hasImage() async => file != null;

  @override
  Future<BookImageFile?> read() async {
    readCount++;
    return file;
  }
}
