import 'package:dnevnik/features/books/domain/book_writing_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('records writing goals, time, words and streaks', () {
    final state =
        const BookWritingState(dailyTargetWords: 500, projectTargetWords: 80000)
            .record(
              startedAt: DateTime(2026, 7, 21, 10),
              duration: const Duration(minutes: 25),
              wordsAdded: 420,
            )
            .record(
              startedAt: DateTime(2026, 7, 22, 11),
              duration: const Duration(minutes: 35),
              wordsAdded: 610,
            );

    expect(state.totalWritingTimeSeconds, 3600);
    expect(state.wordsForDay(DateTime(2026, 7, 22)), 610);
    expect(state.activeDays, 2);
    expect(state.streakAt(DateTime(2026, 7, 22)), 2);
    expect(BookWritingState.fromJson(state.toJson()).projectTargetWords, 80000);
  });

  test('old projects receive an empty safe writing state', () {
    final state = BookWritingState.fromJson(const {});
    expect(state.sessions, isEmpty);
    expect(state.dailyTargetWords, 0);
  });
}
