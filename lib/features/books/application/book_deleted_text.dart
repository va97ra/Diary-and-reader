import 'dart:math' as math;

import 'package:dnevnik/features/books/domain/manuscript_statistics.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter_quill/quill_delta.dart';

/// Finds what one edit deleted from a chapter and puts it back later.
abstract final class BookDeletedText {
  /// Stands for a picture or another embed in the flattened text.
  static const _embedMark = 0xFFFC;

  static final _wordCharacter = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// The fragment that turning [before] into [after] deleted, with the offset
  /// where it began: a whole word or more, or a picture. Erasing a letter or
  /// a keyboard's autocorrection is not a deletion worth keeping.
  static ({int offset, RichDocument content})? between(
    RichDocument before,
    RichDocument after,
  ) {
    final old = _flatten(before);
    final now = _flatten(after);
    // An edit replaces one stretch of text, so what it removed sits between
    // the part both versions start with and the part they end with.
    final limit = math.min(old.length, now.length);
    var start = 0;
    while (start < limit && old.codeUnitAt(start) == now.codeUnitAt(start)) {
      start++;
    }
    var end = old.length;
    var otherEnd = now.length;
    while (end > start &&
        otherEnd > start &&
        old.codeUnitAt(end - 1) == now.codeUnitAt(otherEnd - 1)) {
      end--;
      otherEnd--;
    }
    if (end <= start) return null;
    final removedEmbed = old
        .substring(start, end)
        .codeUnits
        .contains(_embedMark);
    if (!removedEmbed) {
      if (old.length - now.length < 2) return null;
      final lostWords =
          ManuscriptStatistics.fromDocument(before).words -
          ManuscriptStatistics.fromDocument(after).words;
      if (lostWords < 1) return null;
    }
    // Replacing "седое" with "ясное" leaves "ое" in common; keep whole words.
    while (start > 0 && _isWord(old, start - 1) && _isWord(old, start)) {
      start--;
    }
    while (end < old.length && _isWord(old, end - 1) && _isWord(old, end)) {
      end++;
    }
    final fragment = Delta.fromJson(before).slice(start, end);
    return (offset: start, content: _json(fragment));
  }

  /// [content] with [fragment] put back at [offset], or at the end of the
  /// chapter when the chapter has since become shorter. A space keeps it from
  /// running into a word it now stands next to.
  static RichDocument restore(
    RichDocument content,
    int offset,
    RichDocument fragment,
  ) {
    final document = Delta.fromJson(content);
    final text = _flatten(content);
    final piece = _flatten(fragment);
    // The text length, embeds counted once; the final line break stays last.
    final at = offset.clamp(0, text.length - 1);
    final change = Delta()..retain(at);
    if (at > 0 &&
        piece.isNotEmpty &&
        _isWord(text, at - 1) &&
        _isWord(piece, 0)) {
      change.insert(' ');
    }
    Delta.fromJson(fragment).toList().forEach(change.push);
    if (piece.isNotEmpty &&
        _isWord(piece, piece.length - 1) &&
        _isWord(text, at)) {
      change.insert(' ');
    }
    return _json(document.compose(change));
  }

  static bool _isWord(String text, int index) =>
      index >= 0 && index < text.length && _wordCharacter.hasMatch(text[index]);

  static String _flatten(RichDocument document) => document.map((operation) {
    final insert = operation['insert'];
    return insert is String ? insert : String.fromCharCode(_embedMark);
  }).join();

  static RichDocument _json(Delta delta) => [
    for (final operation in delta.toJson())
      Map<String, dynamic>.from(operation as Map),
  ];
}
