class BookWritingSession {
  const BookWritingSession({
    required this.startedAt,
    required this.durationSeconds,
    required this.wordsAdded,
  });

  factory BookWritingSession.fromJson(Map<String, dynamic> json) {
    final startedAt = DateTime.tryParse(json['startedAt']?.toString() ?? '');
    return BookWritingSession(
      startedAt: startedAt ?? DateTime.now(),
      durationSeconds: _nonNegative(json['durationSeconds'], 24 * 60 * 60),
      wordsAdded: _nonNegative(json['wordsAdded'], 10000000),
    );
  }

  final DateTime startedAt;
  final int durationSeconds;
  final int wordsAdded;

  Map<String, Object> toJson() => {
    'startedAt': startedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'wordsAdded': wordsAdded,
  };
}

class BookWritingState {
  const BookWritingState({
    this.dailyTargetWords = 0,
    this.projectTargetWords = 0,
    this.sessions = const [],
  });

  factory BookWritingState.fromJson(Map<String, dynamic> json) =>
      BookWritingState(
        dailyTargetWords: _nonNegative(json['dailyTargetWords'], 10000000),
        projectTargetWords: _nonNegative(json['projectTargetWords'], 10000000),
        sessions:
            (json['sessions'] as List<dynamic>? ?? const [])
                .whereType<Map>()
                .map(
                  (item) => BookWritingSession.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where(
                  (session) =>
                      session.durationSeconds > 0 || session.wordsAdded > 0,
                )
                .toList()
              ..sort((a, b) => a.startedAt.compareTo(b.startedAt)),
      );

  final int dailyTargetWords;
  final int projectTargetWords;
  final List<BookWritingSession> sessions;

  int get totalWritingTimeSeconds =>
      sessions.fold(0, (total, session) => total + session.durationSeconds);

  int wordsForDay(DateTime day) => sessions
      .where((session) => _sameDay(session.startedAt.toLocal(), day.toLocal()))
      .fold(0, (total, session) => total + session.wordsAdded);

  int get activeDays => sessions
      .map((session) => _dayKey(session.startedAt.toLocal()))
      .toSet()
      .length;

  int streakAt(DateTime day) {
    final active = sessions
        .map((session) => _dayKey(session.startedAt.toLocal()))
        .toSet();
    var cursor = DateTime(day.year, day.month, day.day);
    var result = 0;
    while (active.contains(_dayKey(cursor))) {
      result += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return result;
  }

  BookWritingState copyWith({
    int? dailyTargetWords,
    int? projectTargetWords,
    List<BookWritingSession>? sessions,
  }) => BookWritingState(
    dailyTargetWords: (dailyTargetWords ?? this.dailyTargetWords).clamp(
      0,
      10000000,
    ),
    projectTargetWords: (projectTargetWords ?? this.projectTargetWords).clamp(
      0,
      10000000,
    ),
    sessions: sessions ?? this.sessions,
  );

  BookWritingState record({
    required DateTime startedAt,
    required Duration duration,
    required int wordsAdded,
  }) {
    final seconds = duration.inSeconds.clamp(0, 24 * 60 * 60);
    final words = wordsAdded.clamp(0, 10000000);
    if (seconds == 0 && words == 0) return this;
    final next = [
      ...sessions,
      BookWritingSession(
        startedAt: startedAt,
        durationSeconds: seconds,
        wordsAdded: words,
      ),
    ];
    return copyWith(
      sessions: next.length <= 1000 ? next : next.sublist(next.length - 1000),
    );
  }

  Map<String, Object> toJson() => {
    'dailyTargetWords': dailyTargetWords,
    'projectTargetWords': projectTargetWords,
    'sessions': sessions.map((session) => session.toJson()).toList(),
  };
}

int _nonNegative(Object? value, int maximum) {
  final parsed = value is num ? value.toInt() : int.tryParse('$value');
  return (parsed ?? 0).clamp(0, maximum);
}

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _dayKey(DateTime value) => '${value.year}-${value.month}-${value.day}';
