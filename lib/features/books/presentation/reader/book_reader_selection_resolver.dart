import 'dart:math' as math;

import 'package:dnevnik/features/books/presentation/reader/book_reader_text_selection.dart';
import 'package:flutter/services.dart';

class BookReaderSelectionResolver {
  const BookReaderSelectionResolver._();

  static BookReaderTextSelection? resolve({
    required TextSelection selection,
    required int globalStart,
    required int localLength,
    required String plainText,
  }) {
    if (selection.isCollapsed) return null;
    final localStart = math
        .min(selection.baseOffset, selection.extentOffset)
        .clamp(0, localLength);
    final localEnd = math
        .max(selection.baseOffset, selection.extentOffset)
        .clamp(0, localLength);
    if (localEnd <= localStart) return null;
    final start = (globalStart + localStart).clamp(0, plainText.length);
    final end = (globalStart + localEnd).clamp(0, plainText.length);
    if (end <= start) return null;
    final rawText = plainText.substring(start, end);
    final leadingWhitespace = rawText.length - rawText.trimLeft().length;
    final trailingWhitespace = rawText.length - rawText.trimRight().length;
    final adjustedStart = start + leadingWhitespace;
    final adjustedEnd = end - trailingWhitespace;
    if (adjustedEnd <= adjustedStart) return null;
    final text = plainText.substring(adjustedStart, adjustedEnd);
    if (text.isEmpty) return null;
    return BookReaderTextSelection(
      startOffset: adjustedStart,
      endOffset: adjustedEnd,
      text: text,
      sectionProgress: plainText.isEmpty ? 0 : adjustedStart / plainText.length,
    );
  }
}
