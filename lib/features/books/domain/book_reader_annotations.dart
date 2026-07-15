class BookReaderBookmark {
  const BookReaderBookmark({
    required this.id,
    required this.sectionId,
    required this.sectionProgress,
    required this.excerpt,
    required this.createdAt,
  });

  factory BookReaderBookmark.create({
    required String sectionId,
    required double sectionProgress,
    required String excerpt,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return BookReaderBookmark(
      id: 'bookmark-${timestamp.microsecondsSinceEpoch}',
      sectionId: sectionId,
      sectionProgress: _normalized(sectionProgress),
      excerpt: excerpt.trim(),
      createdAt: timestamp,
    );
  }

  factory BookReaderBookmark.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    return BookReaderBookmark(
      id:
          json['id']?.toString() ??
          'bookmark-${createdAt.microsecondsSinceEpoch}',
      sectionId: json['sectionId']?.toString() ?? '',
      sectionProgress: _normalized(json['sectionProgress']),
      excerpt: json['excerpt']?.toString().trim() ?? '',
      createdAt: createdAt,
    );
  }

  final String id;
  final String sectionId;
  final double sectionProgress;
  final String excerpt;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
    'id': id,
    'sectionId': sectionId,
    'sectionProgress': sectionProgress,
    'excerpt': excerpt,
    'createdAt': createdAt.toIso8601String(),
  };
}

class BookReaderNote {
  const BookReaderNote({
    required this.id,
    required this.sectionId,
    required this.sectionProgress,
    required this.excerpt,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookReaderNote.create({
    required String sectionId,
    required double sectionProgress,
    required String excerpt,
    required String text,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return BookReaderNote(
      id: 'note-${timestamp.microsecondsSinceEpoch}',
      sectionId: sectionId,
      sectionProgress: _normalized(sectionProgress),
      excerpt: excerpt.trim(),
      text: text.trim(),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  factory BookReaderNote.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    return BookReaderNote(
      id: json['id']?.toString() ?? 'note-${createdAt.microsecondsSinceEpoch}',
      sectionId: json['sectionId']?.toString() ?? '',
      sectionProgress: _normalized(json['sectionProgress']),
      excerpt: json['excerpt']?.toString().trim() ?? '',
      text: json['text']?.toString().trim() ?? '',
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? createdAt,
    );
  }

  final String id;
  final String sectionId;
  final double sectionProgress;
  final String excerpt;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookReaderNote copyWith({String? text, DateTime? updatedAt}) =>
      BookReaderNote(
        id: id,
        sectionId: sectionId,
        sectionProgress: sectionProgress,
        excerpt: excerpt,
        text: (text ?? this.text).trim(),
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object> toJson() => {
    'id': id,
    'sectionId': sectionId,
    'sectionProgress': sectionProgress,
    'excerpt': excerpt,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

enum BookReaderHighlightColor {
  yellow,
  green,
  blue,
  pink;

  static BookReaderHighlightColor fromJson(Object? value) => values.firstWhere(
    (color) => color.name == value?.toString(),
    orElse: () => BookReaderHighlightColor.yellow,
  );
}

class BookReaderHighlight {
  const BookReaderHighlight({
    required this.id,
    required this.sectionId,
    required this.sectionProgress,
    required this.startOffset,
    required this.endOffset,
    required this.excerpt,
    required this.color,
    required this.createdAt,
  });

  factory BookReaderHighlight.create({
    required String sectionId,
    required double sectionProgress,
    required int startOffset,
    required int endOffset,
    required String excerpt,
    BookReaderHighlightColor color = BookReaderHighlightColor.yellow,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final range = _normalizedRange(startOffset, endOffset);
    return BookReaderHighlight(
      id: 'highlight-${timestamp.microsecondsSinceEpoch}',
      sectionId: sectionId,
      sectionProgress: _normalized(sectionProgress),
      startOffset: range.start,
      endOffset: range.end,
      excerpt: excerpt.trim(),
      color: color,
      createdAt: timestamp,
    );
  }

  factory BookReaderHighlight.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final range = _normalizedRange(json['startOffset'], json['endOffset']);
    return BookReaderHighlight(
      id:
          json['id']?.toString() ??
          'highlight-${createdAt.microsecondsSinceEpoch}',
      sectionId: json['sectionId']?.toString() ?? '',
      sectionProgress: _normalized(json['sectionProgress']),
      startOffset: range.start,
      endOffset: range.end,
      excerpt: json['excerpt']?.toString().trim() ?? '',
      color: BookReaderHighlightColor.fromJson(json['color']),
      createdAt: createdAt,
    );
  }

  final String id;
  final String sectionId;
  final double sectionProgress;
  final int startOffset;
  final int endOffset;
  final String excerpt;
  final BookReaderHighlightColor color;
  final DateTime createdAt;

  BookReaderHighlight copyWith({BookReaderHighlightColor? color}) =>
      BookReaderHighlight(
        id: id,
        sectionId: sectionId,
        sectionProgress: sectionProgress,
        startOffset: startOffset,
        endOffset: endOffset,
        excerpt: excerpt,
        color: color ?? this.color,
        createdAt: createdAt,
      );

  Map<String, Object> toJson() => {
    'id': id,
    'sectionId': sectionId,
    'sectionProgress': sectionProgress,
    'startOffset': startOffset,
    'endOffset': endOffset,
    'excerpt': excerpt,
    'color': color.name,
    'createdAt': createdAt.toIso8601String(),
  };
}

class BookReaderQuote {
  const BookReaderQuote({
    required this.id,
    required this.sectionId,
    required this.sectionProgress,
    required this.startOffset,
    required this.endOffset,
    required this.text,
    required this.createdAt,
  });

  factory BookReaderQuote.create({
    required String sectionId,
    required double sectionProgress,
    required int startOffset,
    required int endOffset,
    required String text,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final range = _normalizedRange(startOffset, endOffset);
    return BookReaderQuote(
      id: 'quote-${timestamp.microsecondsSinceEpoch}',
      sectionId: sectionId,
      sectionProgress: _normalized(sectionProgress),
      startOffset: range.start,
      endOffset: range.end,
      text: text.trim(),
      createdAt: timestamp,
    );
  }

  factory BookReaderQuote.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.now();
    final range = _normalizedRange(json['startOffset'], json['endOffset']);
    return BookReaderQuote(
      id: json['id']?.toString() ?? 'quote-${createdAt.microsecondsSinceEpoch}',
      sectionId: json['sectionId']?.toString() ?? '',
      sectionProgress: _normalized(json['sectionProgress']),
      startOffset: range.start,
      endOffset: range.end,
      text: json['text']?.toString().trim() ?? '',
      createdAt: createdAt,
    );
  }

  final String id;
  final String sectionId;
  final double sectionProgress;
  final int startOffset;
  final int endOffset;
  final String text;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
    'id': id,
    'sectionId': sectionId,
    'sectionProgress': sectionProgress,
    'startOffset': startOffset,
    'endOffset': endOffset,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
}

class BookReaderAnnotations {
  BookReaderAnnotations({
    List<BookReaderBookmark> bookmarks = const [],
    List<BookReaderNote> notes = const [],
    List<BookReaderHighlight> highlights = const [],
    List<BookReaderQuote> quotes = const [],
  }) : bookmarks = List.unmodifiable(bookmarks),
       notes = List.unmodifiable(notes),
       highlights = List.unmodifiable(highlights),
       quotes = List.unmodifiable(quotes);

  factory BookReaderAnnotations.fromJson(Map<String, dynamic> json) =>
      BookReaderAnnotations(
        bookmarks: (json['bookmarks'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  BookReaderBookmark.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((bookmark) => bookmark.sectionId.isNotEmpty)
            .toList(),
        notes: (json['notes'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  BookReaderNote.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((note) => note.sectionId.isNotEmpty && note.text.isNotEmpty)
            .toList(),
        highlights: (json['highlights'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  BookReaderHighlight.fromJson(Map<String, dynamic>.from(item)),
            )
            .where(
              (highlight) =>
                  highlight.sectionId.isNotEmpty &&
                  highlight.excerpt.isNotEmpty &&
                  highlight.endOffset > highlight.startOffset,
            )
            .toList(),
        quotes: (json['quotes'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  BookReaderQuote.fromJson(Map<String, dynamic>.from(item)),
            )
            .where(
              (quote) =>
                  quote.sectionId.isNotEmpty &&
                  quote.text.isNotEmpty &&
                  quote.endOffset > quote.startOffset,
            )
            .toList(),
      );

  final List<BookReaderBookmark> bookmarks;
  final List<BookReaderNote> notes;
  final List<BookReaderHighlight> highlights;
  final List<BookReaderQuote> quotes;

  BookReaderAnnotations addBookmark(BookReaderBookmark bookmark) =>
      _copyWith(bookmarks: [...bookmarks, bookmark]);

  BookReaderAnnotations removeBookmark(String id) => _copyWith(
    bookmarks: bookmarks.where((bookmark) => bookmark.id != id).toList(),
  );

  BookReaderAnnotations addNote(BookReaderNote note) =>
      _copyWith(notes: [...notes, note]);

  BookReaderAnnotations updateNote(BookReaderNote note) => _copyWith(
    notes: notes.map((item) => item.id == note.id ? note : item).toList(),
  );

  BookReaderAnnotations removeNote(String id) =>
      _copyWith(notes: notes.where((note) => note.id != id).toList());

  BookReaderAnnotations addHighlight(BookReaderHighlight highlight) {
    final retained = highlights
        .where(
          (item) =>
              item.sectionId != highlight.sectionId ||
              item.endOffset <= highlight.startOffset ||
              item.startOffset >= highlight.endOffset,
        )
        .toList();
    return _copyWith(highlights: [...retained, highlight]);
  }

  BookReaderAnnotations updateHighlight(BookReaderHighlight highlight) =>
      _copyWith(
        highlights: highlights
            .map((item) => item.id == highlight.id ? highlight : item)
            .toList(),
      );

  BookReaderAnnotations removeHighlight(String id) => _copyWith(
    highlights: highlights.where((highlight) => highlight.id != id).toList(),
  );

  BookReaderAnnotations addQuote(BookReaderQuote quote) {
    final exists = quotes.any(
      (item) =>
          item.sectionId == quote.sectionId &&
          item.startOffset == quote.startOffset &&
          item.endOffset == quote.endOffset,
    );
    return exists ? this : _copyWith(quotes: [...quotes, quote]);
  }

  BookReaderAnnotations removeQuote(String id) =>
      _copyWith(quotes: quotes.where((quote) => quote.id != id).toList());

  BookReaderAnnotations retainSections(Set<String> sectionIds) => _copyWith(
    bookmarks: bookmarks
        .where((bookmark) => sectionIds.contains(bookmark.sectionId))
        .toList(),
    notes: notes.where((note) => sectionIds.contains(note.sectionId)).toList(),
    highlights: highlights
        .where((highlight) => sectionIds.contains(highlight.sectionId))
        .toList(),
    quotes: quotes
        .where((quote) => sectionIds.contains(quote.sectionId))
        .toList(),
  );

  Map<String, Object> toJson() => {
    'bookmarks': bookmarks.map((bookmark) => bookmark.toJson()).toList(),
    'notes': notes.map((note) => note.toJson()).toList(),
    'highlights': highlights.map((highlight) => highlight.toJson()).toList(),
    'quotes': quotes.map((quote) => quote.toJson()).toList(),
  };

  BookReaderAnnotations _copyWith({
    List<BookReaderBookmark>? bookmarks,
    List<BookReaderNote>? notes,
    List<BookReaderHighlight>? highlights,
    List<BookReaderQuote>? quotes,
  }) => BookReaderAnnotations(
    bookmarks: bookmarks ?? this.bookmarks,
    notes: notes ?? this.notes,
    highlights: highlights ?? this.highlights,
    quotes: quotes ?? this.quotes,
  );
}

double _normalized(Object? value) {
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  return (parsed ?? 0).clamp(0, 1).toDouble();
}

({int start, int end}) _normalizedRange(Object? start, Object? end) {
  final parsedStart = start is num
      ? start.toInt()
      : int.tryParse('$start') ?? 0;
  final parsedEnd = end is num ? end.toInt() : int.tryParse('$end') ?? 0;
  final lower = parsedStart < parsedEnd ? parsedStart : parsedEnd;
  final upper = parsedStart < parsedEnd ? parsedEnd : parsedStart;
  return (start: lower.clamp(0, 0x7fffffff), end: upper.clamp(0, 0x7fffffff));
}
