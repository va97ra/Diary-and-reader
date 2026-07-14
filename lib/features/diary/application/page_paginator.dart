import 'package:dnevnik/features/diary/domain/diary_entry.dart';

class PageSplit {
  const PageSplit({required this.visible, required this.overflow});

  final PageDocument visible;
  final PageDocument overflow;
}

abstract final class PagePaginator {
  static PageSplit split(PageDocument source, int splitOffset) {
    final documentLength = _length(source);
    final safeOffset = splitOffset.clamp(1, documentLength - 1);
    final visible = _slice(source, 0, safeOffset);
    final overflow = _slice(source, safeOffset, documentLength);

    if (!_endsWithNewline(visible)) {
      final attributes = _nextNewlineAttributes(source, safeOffset);
      visible.add({'insert': '\n', 'attributes': ?attributes});
    }
    if (!_endsWithNewline(overflow)) {
      overflow.add(<String, dynamic>{'insert': '\n'});
    }
    return PageSplit(visible: visible, overflow: overflow);
  }

  static PageDocument prependOverflow(
    PageDocument overflow,
    PageDocument nextPage,
  ) {
    if (_isBlank(nextPage)) return _copy(overflow);
    return [..._copy(overflow), ..._copy(nextPage)];
  }

  static int _length(PageDocument document) {
    return document.fold(0, (sum, operation) {
      final insert = operation['insert'];
      return sum + (insert is String ? insert.length : 1);
    });
  }

  static PageDocument _slice(PageDocument source, int start, int end) {
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
    PageDocument source,
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

  static bool _endsWithNewline(PageDocument document) {
    if (document.isEmpty) return false;
    final insert = document.last['insert'];
    return insert is String && insert.endsWith('\n');
  }

  static bool _isBlank(PageDocument document) {
    return document.every((operation) {
      final insert = operation['insert'];
      return insert is String && insert.trim().isEmpty;
    });
  }

  static PageDocument _copy(PageDocument document) {
    return document.map(Map<String, dynamic>.from).toList();
  }
}
