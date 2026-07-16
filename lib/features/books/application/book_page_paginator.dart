import 'dart:convert';

import 'package:dnevnik/features/books/domain/rich_document.dart';

class BookPageSplit {
  const BookPageSplit({required this.visible, required this.overflow});

  final RichDocument visible;
  final RichDocument overflow;
}

/// Splits a Quill Delta into screen pages without adding hard paragraph
/// breaks to the saved manuscript.
abstract final class BookPagePaginator {
  static const _softPageBreakAttribute = '_bookSoftPageBreak';

  /// Returns the first author-inserted page break that fits inside the
  /// measured page. The break stays in the manuscript, while its following
  /// content starts on a new page.
  static BookPageSplit? splitAtFirstHardPageBreak(
    RichDocument source,
    int measuredSplitOffset,
  ) {
    final splitOffset = _firstHardPageBreakEnd(source);
    if (splitOffset == null || splitOffset > measuredSplitOffset) return null;
    final documentLength = _length(source);
    final visible = _slice(source, 0, splitOffset);
    final overflow = splitOffset < documentLength
        ? _slice(source, splitOffset, documentLength)
        : emptyRichDocument();
    if (!_endsWithNewline(visible)) {
      visible.add(<String, dynamic>{'insert': '\n'});
    }
    if (!_endsWithNewline(overflow)) {
      overflow.add(<String, dynamic>{'insert': '\n'});
    }
    return BookPageSplit(visible: visible, overflow: overflow);
  }

  static BookPageSplit split(RichDocument source, int splitOffset) {
    final documentLength = _length(source);
    final safeOffset = splitOffset.clamp(1, documentLength - 1);
    final visible = _slice(source, 0, safeOffset);
    final overflow = _slice(source, safeOffset, documentLength);

    if (!_endsWithNewline(visible)) {
      final attributes = <String, dynamic>{
        ...?_nextNewlineAttributes(source, safeOffset),
        _softPageBreakAttribute: true,
      };
      visible.add({'insert': '\n', 'attributes': attributes});
    }
    if (!_endsWithNewline(overflow)) {
      overflow.add(<String, dynamic>{'insert': '\n'});
    }
    return BookPageSplit(visible: visible, overflow: overflow);
  }

  static RichDocument prependOverflow(
    RichDocument overflow,
    RichDocument nextPage,
  ) {
    if (_isBlank(nextPage)) return _copy(overflow);
    return [..._copy(overflow), ..._copy(nextPage)];
  }

  static RichDocument merge(Iterable<RichDocument> pages) {
    final merged = <Map<String, dynamic>>[];
    for (final page in pages) {
      final operations = _copy(page);
      if (operations.isNotEmpty && _isSoftPageBreak(operations.last)) {
        operations.removeLast();
      }
      for (final operation in operations) {
        _appendNormalized(merged, operation);
      }
    }
    return merged.isEmpty ? emptyRichDocument() : merged;
  }

  static bool _isSoftPageBreak(Map<String, dynamic> operation) {
    final attributes = operation['attributes'];
    return operation['insert'] == '\n' &&
        attributes is Map &&
        attributes[_softPageBreakAttribute] == true;
  }

  static void _appendNormalized(
    RichDocument target,
    Map<String, dynamic> operation,
  ) {
    final insert = operation['insert'];
    if (target.isNotEmpty &&
        insert is String &&
        target.last['insert'] is String &&
        _sameAttributes(target.last['attributes'], operation['attributes'])) {
      target.last['insert'] = '${target.last['insert']}$insert';
      return;
    }
    target.add(Map<String, dynamic>.from(operation));
  }

  static bool _sameAttributes(Object? first, Object? second) =>
      jsonEncode(first) == jsonEncode(second);

  static int _length(RichDocument document) =>
      document.fold(0, (sum, operation) {
        final insert = operation['insert'];
        return sum + (insert is String ? insert.length : 1);
      });

  static int? _firstHardPageBreakEnd(RichDocument source) {
    var position = 0;
    for (var index = 0; index < source.length; index++) {
      final operation = source[index];
      final insert = operation['insert'];
      final operationLength = insert is String ? insert.length : 1;
      if (insert is Map && _isHardPageBreak(insert)) {
        var end = position + 1;
        if (index + 1 < source.length) {
          final nextInsert = source[index + 1]['insert'];
          if (nextInsert is String && nextInsert.startsWith('\n')) end++;
        }
        return end;
      }
      position += operationLength;
    }
    return null;
  }

  static bool _isHardPageBreak(Map insert) {
    if (insert['bookPageBreak'] != null) return true;
    final custom = insert['custom'];
    if (custom is! String) return false;
    try {
      final decoded = jsonDecode(custom);
      return decoded is Map && decoded['bookPageBreak'] != null;
    } on FormatException {
      return false;
    }
  }

  static RichDocument _slice(RichDocument source, int start, int end) {
    final result = <Map<String, dynamic>>[];
    var position = 0;
    for (final operation in source) {
      final insert = operation['insert'];
      final operationLength = insert is String ? insert.length : 1;
      final operationEnd = position + operationLength;
      final overlapStart = start > position ? start : position;
      final overlapEnd = end < operationEnd ? end : operationEnd;
      if (overlapStart < overlapEnd) {
        final sliced = Map<String, dynamic>.from(operation);
        if (insert is String) {
          sliced['insert'] = insert.substring(
            overlapStart - position,
            overlapEnd - position,
          );
        }
        result.add(sliced);
      }
      position = operationEnd;
      if (position >= end) break;
    }
    return result;
  }

  static Map<String, dynamic>? _nextNewlineAttributes(
    RichDocument source,
    int start,
  ) {
    var position = 0;
    for (final operation in source) {
      final insert = operation['insert'];
      final length = insert is String ? insert.length : 1;
      if (insert is String && position + length > start) {
        final localStart = (start - position).clamp(0, insert.length);
        if (insert.indexOf('\n', localStart) >= 0) {
          final attributes = operation['attributes'];
          return attributes is Map
              ? Map<String, dynamic>.from(attributes)
              : null;
        }
      }
      position += length;
    }
    return null;
  }

  static bool _endsWithNewline(RichDocument document) {
    if (document.isEmpty) return false;
    final insert = document.last['insert'];
    return insert is String && insert.endsWith('\n');
  }

  static bool _isBlank(RichDocument document) => document.every((operation) {
    final insert = operation['insert'];
    return insert is String && insert.trim().isEmpty;
  });

  static RichDocument _copy(RichDocument document) =>
      document.map(Map<String, dynamic>.from).toList();
}
