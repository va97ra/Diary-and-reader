import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookManuscriptMatch {
  const BookManuscriptMatch({
    required this.sectionId,
    required this.sectionTitle,
    required this.offset,
    required this.length,
    required this.excerpt,
  });

  final String sectionId;
  final String sectionTitle;
  final int offset;
  final int length;
  final String excerpt;
}

class BookDocumentReplacement {
  const BookDocumentReplacement({required this.document, required this.count});

  final RichDocument document;
  final int count;
}

abstract final class BookManuscriptSearch {
  static List<BookManuscriptMatch> find(
    BookProject project,
    String query, {
    bool caseSensitive = false,
  }) {
    if (query.isEmpty) return const [];
    final matches = <BookManuscriptMatch>[];
    for (final section in project.sections) {
      matches.addAll(
        _findInSection(section, query, caseSensitive: caseSensitive),
      );
    }
    return matches;
  }

  static BookDocumentReplacement replaceAll(
    RichDocument source,
    String query,
    String replacement, {
    bool caseSensitive = false,
  }) {
    if (query.isEmpty) {
      return BookDocumentReplacement(document: source, count: 0);
    }
    final document = Document.fromJson(source);
    final offsets = _offsets(
      document.toPlainText(),
      query,
      caseSensitive: caseSensitive,
    );
    for (final offset in offsets.reversed) {
      document.replace(offset, query.length, replacement);
    }
    return BookDocumentReplacement(
      document: document
          .toDelta()
          .toJson()
          .map((operation) => Map<String, dynamic>.from(operation))
          .toList(),
      count: offsets.length,
    );
  }

  static Iterable<BookManuscriptMatch> _findInSection(
    BookSection section,
    String query, {
    required bool caseSensitive,
  }) sync* {
    final text = Document.fromJson(section.content).toPlainText();
    for (final offset in _offsets(text, query, caseSensitive: caseSensitive)) {
      yield BookManuscriptMatch(
        sectionId: section.id,
        sectionTitle: section.title,
        offset: offset,
        length: query.length,
        excerpt: _excerpt(text, offset, query.length),
      );
    }
  }

  static List<int> _offsets(
    String text,
    String query, {
    required bool caseSensitive,
  }) {
    final searchable = caseSensitive ? text : text.toLowerCase();
    final needle = caseSensitive ? query : query.toLowerCase();
    final offsets = <int>[];
    var offset = 0;
    while (offset <= searchable.length - needle.length) {
      final found = searchable.indexOf(needle, offset);
      if (found < 0) break;
      offsets.add(found);
      offset = found + needle.length;
    }
    return offsets;
  }

  static String _excerpt(String text, int offset, int length) {
    const radius = 44;
    final start = (offset - radius).clamp(0, text.length);
    final end = (offset + length + radius).clamp(0, text.length);
    final normalized = text
        .substring(start, end)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${start > 0 ? '…' : ''}$normalized${end < text.length ? '…' : ''}';
  }
}
