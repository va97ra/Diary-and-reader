import 'dart:async';

import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_image_file.dart';
import 'package:dnevnik/features/books/domain/book_image_placement.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

typedef BookImageTapCallback =
    void Function(
      QuillController controller,
      int offset,
      BookImagePlacement placement,
    );

typedef BookImagePasteCallback =
    Future<bool> Function(QuillController controller);

typedef BookImageFileInsertCallback =
    Future<void> Function(QuillController controller, BookImageFile file);

/// Tracks which illustration is selected for on-page editing. Only one
/// illustration across all page editors of a section can be selected.
class BookImageSelection extends ChangeNotifier {
  final _listeners = <QuillController, VoidCallback>{};
  QuillController? _controller;
  int? _offset;
  int _documentLength = 0;
  int _editDepth = 0;
  bool _swallowEditorTap = false;

  bool isSelected(QuillController controller, int offset) =>
      _controller == controller && _offset == offset;

  bool isAttached(QuillController controller) =>
      _listeners.containsKey(controller);

  /// Starts watching [controller] so that typing or moving the cursor drops
  /// the illustration selection.
  void attach(QuillController controller) {
    if (_listeners.containsKey(controller)) return;
    void listener() {
      if (_editDepth > 0 || _controller != controller) return;
      // Quill still moves the cursor next to a tapped embed; that must not
      // drop the selection the tap has just made.
      final offset = _offset!;
      final cursor = controller.selection;
      final cursorAtImage =
          cursor.isCollapsed &&
          (cursor.baseOffset == offset || cursor.baseOffset == offset + 1);
      if (cursorAtImage && controller.document.length == _documentLength) {
        return;
      }
      clear();
    }

    _listeners[controller] = listener;
    controller.addListener(listener);
  }

  void detach(QuillController controller) {
    final listener = _listeners.remove(controller);
    if (listener != null) controller.removeListener(listener);
    if (_controller == controller) clear();
  }

  /// Called when an illustration handles a tap. Quill still processes the
  /// same tap afterwards (its tap recognizer is transparent) and would move
  /// the cursor and open the keyboard; the editor's `onTapUp` hook asks
  /// [takeEditorTap] to skip it. The flag expires with the pointer event.
  void swallowEditorTap() {
    _swallowEditorTap = true;
    scheduleMicrotask(() => _swallowEditorTap = false);
  }

  bool takeEditorTap() {
    final swallow = _swallowEditorTap;
    _swallowEditorTap = false;
    return swallow;
  }

  void select(QuillController controller, int offset) {
    if (isSelected(controller, offset)) return;
    _controller = controller;
    _offset = offset;
    _documentLength = controller.document.length;
    notifyListeners();
  }

  void clear() {
    if (_controller == null) return;
    _controller = null;
    _offset = null;
    notifyListeners();
  }

  /// Applies an edit made by the illustration controls. The edit returns the
  /// illustration's new offset to keep it selected, or null to deselect.
  void edit(QuillController controller, int? Function() change) {
    _editDepth++;
    int? offset;
    try {
      offset = change();
    } finally {
      _editDepth--;
    }
    if (offset == null) {
      clear();
    } else {
      _controller = controller;
      _offset = offset;
      _documentLength = controller.document.length;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final entry in _listeners.entries) {
      entry.key.removeListener(entry.value);
    }
    _listeners.clear();
    super.dispose();
  }
}

/// Provides illustration editing services to the editors and embeds below it.
class BookImageEditingScope extends InheritedWidget {
  const BookImageEditingScope({
    required this.selection,
    required super.child,
    this.onOpenSettings,
    this.onPasteImage,
    this.clipboardHasImage,
    this.onInsertImageFile,
    super.key,
  });

  final BookImageSelection selection;
  final BookImageTapCallback? onOpenSettings;
  final BookImagePasteCallback? onPasteImage;
  final Future<bool> Function()? clipboardHasImage;
  final BookImageFileInsertCallback? onInsertImageFile;

  static BookImageEditingScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BookImageEditingScope>();

  static const _keyboardImageTypes = [
    'image/png',
    'image/jpeg',
    'image/gif',
    'image/webp',
  ];

  /// Accepts images committed by the keyboard, such as Gboard's clipboard
  /// strip, stickers, and GIFs.
  ContentInsertionConfiguration? contentInsertionFor(
    QuillController controller,
  ) {
    final insert = onInsertImageFile;
    if (insert == null) return null;
    return ContentInsertionConfiguration(
      allowedMimeTypes: _keyboardImageTypes,
      onContentInserted: (content) {
        final bytes = content.data;
        if (bytes == null || bytes.isEmpty) return;
        insert(controller, BookImageFile(name: content.uri, bytes: bytes));
      },
    );
  }

  /// Passed to `QuillEditorConfig.onTapUp`; returns true to make Quill
  /// ignore a tap that an illustration has already handled.
  bool handleEditorTapUp(
    TapUpDetails details,
    TextPosition Function(Offset offset) getPositionForOffset,
  ) => selection.takeEditorTap();

  QuillEditorContextMenuBuilder? get contextMenuBuilder {
    final paste = onPasteImage;
    final hasImage = clipboardHasImage;
    if (paste == null || hasImage == null) return null;
    return (context, state) => _BookEditorContextMenu(
      state: state,
      clipboardHasImage: hasImage,
      onPasteImage: paste,
    );
  }

  @override
  bool updateShouldNotify(BookImageEditingScope oldWidget) =>
      selection != oldWidget.selection ||
      onOpenSettings != oldWidget.onOpenSettings ||
      onPasteImage != oldWidget.onPasteImage ||
      clipboardHasImage != oldWidget.clipboardHasImage ||
      onInsertImageFile != oldWidget.onInsertImageFile;
}

/// The regular text selection menu plus "Paste image" when the clipboard
/// holds a picture. Android hides its own Paste item when the clipboard has
/// no text, so without this entry a copied picture cannot be pasted at all.
class _BookEditorContextMenu extends StatefulWidget {
  const _BookEditorContextMenu({
    required this.state,
    required this.clipboardHasImage,
    required this.onPasteImage,
  });

  final QuillRawEditorState state;
  final Future<bool> Function() clipboardHasImage;
  final BookImagePasteCallback onPasteImage;

  @override
  State<_BookEditorContextMenu> createState() => _BookEditorContextMenuState();
}

class _BookEditorContextMenuState extends State<_BookEditorContextMenu> {
  bool _hasImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.state.widget.config.readOnly) return;
    widget.clipboardHasImage().then((hasImage) {
      if (mounted && hasImage) setState(() => _hasImage = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = [...widget.state.contextMenuButtonItems];
    if (_hasImage) {
      final pasteIndex = items.indexWhere(
        (item) => item.type == ContextMenuButtonType.paste,
      );
      items.insert(
        pasteIndex < 0 ? items.length : pasteIndex + 1,
        ContextMenuButtonItem(
          label: AppStrings.of(context).pasteImage,
          onPressed: () {
            final controller = widget.state.controller;
            widget.state.hideToolbar();
            widget.onPasteImage(controller);
          },
        ),
      );
    }
    return TextFieldTapRegion(
      child: AdaptiveTextSelectionToolbar.buttonItems(
        buttonItems: items,
        anchors: widget.state.contextMenuAnchors,
      ),
    );
  }
}

/// Keyboard shortcut helper shared by the editors: whether an image paste
/// should take precedence over the regular text paste.
Future<bool> bookClipboardPrefersImage(
  Future<bool> Function()? clipboardHasImage,
) async {
  if (clipboardHasImage == null) return false;
  if (!await clipboardHasImage()) return false;
  return !(await Clipboard.hasStrings());
}
