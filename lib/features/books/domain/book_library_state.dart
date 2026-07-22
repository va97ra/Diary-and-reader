enum BookReadingStatus { automatic, wantToRead, reading, paused, finished }

class BookLibraryState {
  const BookLibraryState({
    this.isFavorite = false,
    this.readingStatus = BookReadingStatus.automatic,
    this.lastReadAt,
    this.readingTimeSeconds = 0,
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
  );

  final bool isFavorite;
  final BookReadingStatus readingStatus;
  final DateTime? lastReadAt;
  final int readingTimeSeconds;

  BookLibraryState copyWith({
    bool? isFavorite,
    BookReadingStatus? readingStatus,
    DateTime? lastReadAt,
    int? readingTimeSeconds,
  }) => BookLibraryState(
    isFavorite: isFavorite ?? this.isFavorite,
    readingStatus: readingStatus ?? this.readingStatus,
    lastReadAt: lastReadAt ?? this.lastReadAt,
    readingTimeSeconds: readingTimeSeconds ?? this.readingTimeSeconds,
  );

  BookLibraryState recordReading(Duration duration, {DateTime? now}) =>
      copyWith(
        lastReadAt: now ?? DateTime.now(),
        readingTimeSeconds:
            readingTimeSeconds + duration.inSeconds.clamp(0, 86400).toInt(),
      );

  Map<String, dynamic> toJson() => {
    'isFavorite': isFavorite,
    'readingStatus': readingStatus.name,
    'lastReadAt': lastReadAt?.toIso8601String(),
    'readingTimeSeconds': readingTimeSeconds,
  };
}
