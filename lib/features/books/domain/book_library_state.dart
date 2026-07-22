enum BookReadingStatus { automatic, wantToRead, reading, paused, finished }

class BookReadingSession {
  const BookReadingSession({
    required this.startedAt,
    required this.durationSeconds,
  });

  factory BookReadingSession.fromJson(Map<String, dynamic> json) {
    final startedAt = DateTime.tryParse(json['startedAt']?.toString() ?? '');
    final seconds = json['durationSeconds'];
    return BookReadingSession(
      startedAt: startedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      durationSeconds: seconds is num
          ? seconds.toInt().clamp(0, 86400).toInt()
          : 0,
    );
  }

  final DateTime startedAt;
  final int durationSeconds;

  Map<String, dynamic> toJson() => {
    'startedAt': startedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
  };
}

class BookLibraryState {
  const BookLibraryState({
    this.isFavorite = false,
    this.readingStatus = BookReadingStatus.automatic,
    this.lastReadAt,
    this.readingTimeSeconds = 0,
    this.readingSessions = const [],
  });

  factory BookLibraryState.fromJson(
    Map<String, dynamic> json,
  ) => BookLibraryState(
    isFavorite: json['isFavorite'] == true,
    readingStatus:
        BookReadingStatus.values
            .where((value) => value.name == json['readingStatus']?.toString())
            .firstOrNull ??
        BookReadingStatus.automatic,
    lastReadAt: DateTime.tryParse(json['lastReadAt']?.toString() ?? ''),
    readingTimeSeconds: json['readingTimeSeconds'] is num
        ? (json['readingTimeSeconds'] as num).toInt().clamp(0, 1 << 62).toInt()
        : 0,
    readingSessions: (json['readingSessions'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              BookReadingSession.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((session) => session.durationSeconds > 0)
        .take(100)
        .toList(growable: false),
  );

  final bool isFavorite;
  final BookReadingStatus readingStatus;
  final DateTime? lastReadAt;
  final int readingTimeSeconds;
  final List<BookReadingSession> readingSessions;

  BookLibraryState copyWith({
    bool? isFavorite,
    BookReadingStatus? readingStatus,
    DateTime? lastReadAt,
    int? readingTimeSeconds,
    List<BookReadingSession>? readingSessions,
  }) => BookLibraryState(
    isFavorite: isFavorite ?? this.isFavorite,
    readingStatus: readingStatus ?? this.readingStatus,
    lastReadAt: lastReadAt ?? this.lastReadAt,
    readingTimeSeconds: readingTimeSeconds ?? this.readingTimeSeconds,
    readingSessions: readingSessions ?? this.readingSessions,
  );

  BookLibraryState recordReading(Duration duration, {DateTime? now}) {
    final finishedAt = now ?? DateTime.now();
    final seconds = duration.inSeconds.clamp(0, 86400).toInt();
    final sessions = seconds == 0
        ? readingSessions
        : [
            BookReadingSession(
              startedAt: finishedAt.subtract(Duration(seconds: seconds)),
              durationSeconds: seconds,
            ),
            ...readingSessions,
          ].take(100).toList(growable: false);
    return copyWith(
      lastReadAt: finishedAt,
      readingTimeSeconds: readingTimeSeconds + seconds,
      readingSessions: sessions,
    );
  }

  Map<String, dynamic> toJson() => {
    'isFavorite': isFavorite,
    'readingStatus': readingStatus.name,
    'lastReadAt': lastReadAt?.toIso8601String(),
    'readingTimeSeconds': readingTimeSeconds,
    'readingSessions': readingSessions
        .map((session) => session.toJson())
        .toList(),
  };
}
