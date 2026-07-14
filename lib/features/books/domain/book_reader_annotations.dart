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

class BookReaderAnnotations {
  BookReaderAnnotations({
    List<BookReaderBookmark> bookmarks = const [],
    List<BookReaderNote> notes = const [],
  }) : bookmarks = List.unmodifiable(bookmarks),
       notes = List.unmodifiable(notes);

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
      );

  final List<BookReaderBookmark> bookmarks;
  final List<BookReaderNote> notes;

  BookReaderAnnotations addBookmark(BookReaderBookmark bookmark) =>
      BookReaderAnnotations(bookmarks: [...bookmarks, bookmark], notes: notes);

  BookReaderAnnotations removeBookmark(String id) => BookReaderAnnotations(
    bookmarks: bookmarks.where((bookmark) => bookmark.id != id).toList(),
    notes: notes,
  );

  BookReaderAnnotations addNote(BookReaderNote note) =>
      BookReaderAnnotations(bookmarks: bookmarks, notes: [...notes, note]);

  BookReaderAnnotations updateNote(BookReaderNote note) =>
      BookReaderAnnotations(
        bookmarks: bookmarks,
        notes: notes.map((item) => item.id == note.id ? note : item).toList(),
      );

  BookReaderAnnotations removeNote(String id) => BookReaderAnnotations(
    bookmarks: bookmarks,
    notes: notes.where((note) => note.id != id).toList(),
  );

  BookReaderAnnotations retainSections(Set<String> sectionIds) =>
      BookReaderAnnotations(
        bookmarks: bookmarks
            .where((bookmark) => sectionIds.contains(bookmark.sectionId))
            .toList(),
        notes: notes
            .where((note) => sectionIds.contains(note.sectionId))
            .toList(),
      );

  Map<String, Object> toJson() => {
    'bookmarks': bookmarks.map((bookmark) => bookmark.toJson()).toList(),
    'notes': notes.map((note) => note.toJson()).toList(),
  };
}

double _normalized(Object? value) {
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  return (parsed ?? 0).clamp(0, 1).toDouble();
}
