import 'dart:convert';

import 'package:dnevnik/features/books/domain/book_image_placement.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

/// Edits illustration embeds in a Quill document. An illustration always
/// occupies its own line: `[bookImage embed]\n`.
///
/// Replacing, removing, and moving leave the editor focus alone: otherwise
/// Quill opens the keyboard over the page on every illustration tweak.
///
/// Illustrations are stored as direct `bookImage` embeds. Quill hands embed
/// builders a detached copy of `custom`-wrapped embeds, so their document
/// offset would be unknown to the on-page controls.
abstract final class BookImageDocumentEditing {
  static const embedType = 'bookImage';

  static BlockEmbed _embed(BookImagePlacement placement) =>
      BlockEmbed(embedType, placement.encode());

  static Map<String, dynamic> _embedJson(BookImagePlacement placement) => {
    embedType: placement.encode(),
  };

  /// Rewrites legacy `custom`-wrapped illustrations as direct embeds so the
  /// editor works with attached nodes. Other operations are kept as they are.
  static RichDocument normalizeEmbeds(RichDocument document) {
    if (!document.any((operation) => operation['insert'] is Map)) {
      return document;
    }
    return [
      for (final operation in document)
        if (operation['insert'] case final Map insert
            when insert[embedType] == null && imageData(insert) != null)
          {
            ...operation,
            'insert': {embedType: imageData(insert)},
          }
        else
          operation,
    ];
  }

  /// Reads the illustration stored at [offset], or null when there is none.
  static BookImagePlacement? placementAt(
    QuillController controller,
    int offset,
  ) {
    var position = 0;
    for (final operation in controller.document.toDelta().toList()) {
      final data = operation.data;
      final length = data is String ? data.length : 1;
      if (offset < position + length) {
        if (data is! Map) return null;
        final raw = imageData(data);
        return raw == null ? null : BookImagePlacement.decode(raw);
      }
      position += length;
    }
    return null;
  }

  /// Extracts the placement payload from both authored (`bookImage`) and
  /// legacy (`custom`) embed maps.
  static String? imageData(Map<dynamic, dynamic> insert) {
    final direct = insert[embedType]?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final custom = insert['custom'];
    if (custom is! String) return null;
    try {
      final decoded = jsonDecode(custom);
      return decoded is Map ? decoded[embedType]?.toString() : null;
    } on FormatException {
      return null;
    }
  }

  /// Inserts [placement] on its own line at [requestedOffset] and places the
  /// cursor after it. Returns the offset of the inserted embed.
  static int insert(
    QuillController controller,
    int requestedOffset,
    BookImagePlacement placement,
  ) {
    final lastOffset = controller.document.length - 1;
    var offset = requestedOffset.clamp(0, lastOffset);
    // At the end of a paragraph the illustration starts the next line instead
    // of leaving an empty paragraph after it.
    if (!_startsLine(controller, offset) &&
        offset < lastOffset &&
        controller.document.toPlainText()[offset] == '\n') {
      offset++;
    }
    final startsLine = _startsLine(controller, offset);
    final insertion = Delta();
    if (!startsLine) insertion.insert('\n');
    insertion
      ..insert(_embedJson(placement))
      ..insert('\n');
    controller.replaceText(offset, 0, insertion, null);
    final cursorOffset = (offset + insertion.length).clamp(
      0,
      controller.document.length - 1,
    );
    controller.updateSelection(
      TextSelection.collapsed(offset: cursorOffset),
      ChangeSource.local,
    );
    return startsLine ? offset : offset + 1;
  }

  static bool replace(
    QuillController controller,
    int offset,
    BookImagePlacement placement,
  ) {
    if (placementAt(controller, offset) == null) return false;
    controller.replaceText(
      offset,
      1,
      _embed(placement),
      null,
      ignoreFocus: true,
    );
    return true;
  }

  /// Removes the illustration together with its line so no blank paragraph
  /// is left behind.
  static bool remove(QuillController controller, int offset) {
    if (placementAt(controller, offset) == null) return false;
    controller.replaceText(
      offset,
      _removalLength(controller, offset),
      '',
      null,
      ignoreFocus: true,
    );
    return true;
  }

  /// Moves the illustration at [from] so that it starts the line at
  /// [targetOffset] (an offset in the current document). The move is a single
  /// change, so one undo restores the previous position. Returns the new
  /// offset of the illustration, or null when nothing moved.
  static int? move(QuillController controller, int from, int targetOffset) {
    final placement = placementAt(controller, from);
    if (placement == null) return null;
    final removal = _removalLength(controller, from);
    final target = targetOffset.clamp(0, controller.document.length - 1);
    if (target >= from && target <= from + removal) return null;

    final startsLine = _startsLine(controller, target);
    final insertion = Delta();
    if (!startsLine) insertion.insert('\n');
    insertion
      ..insert(_embedJson(placement))
      ..insert('\n');

    final change = Delta();
    final int newOffset;
    if (target < from) {
      change.retain(target);
      insertion.toList().forEach(change.push);
      change
        ..retain(from - target)
        ..delete(removal);
      newOffset = target + (startsLine ? 0 : 1);
    } else {
      change
        ..retain(from)
        ..delete(removal)
        ..retain(target - from - removal);
      insertion.toList().forEach(change.push);
      newOffset = target - removal + (startsLine ? 0 : 1);
    }
    final lengthAfter = controller.document.length + insertion.length - removal;
    controller.ignoreFocusOnTextChange = true;
    try {
      controller.compose(
        change,
        TextSelection.collapsed(
          offset: (newOffset + 2).clamp(0, lengthAfter - 1),
        ),
        ChangeSource.local,
      );
    } finally {
      controller.ignoreFocusOnTextChange = false;
    }
    return newOffset;
  }

  static bool _startsLine(QuillController controller, int offset) {
    if (offset == 0) return true;
    final plainText = controller.document.toPlainText();
    return offset <= plainText.length && plainText[offset - 1] == '\n';
  }

  static int _removalLength(QuillController controller, int offset) {
    // The last line's newline cannot be deleted, so an illustration at the
    // very end only loses its embed.
    return offset + 1 < controller.document.length - 1 ? 2 : 1;
  }
}
