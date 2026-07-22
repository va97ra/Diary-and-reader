import 'package:dnevnik/features/books/domain/book_library_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('records bounded reading sessions and preserves old payloads', () {
    final oldPayload = BookLibraryState.fromJson({
      'readingTimeSeconds': 30,
      'lastReadAt': '2026-01-01T10:00:00.000',
    });

    expect(oldPayload.readingSessions, isEmpty);

    var state = oldPayload;
    for (var index = 0; index < 105; index++) {
      state = state.recordReading(
        const Duration(seconds: 15),
        now: DateTime(2026, 1, 2).add(Duration(minutes: index)),
      );
    }

    expect(state.readingTimeSeconds, 1605);
    expect(state.readingSessions, hasLength(100));
    expect(state.readingSessions.first.durationSeconds, 15);

    final restored = BookLibraryState.fromJson(state.toJson());
    expect(restored.readingSessions, hasLength(100));
    expect(
      restored.readingSessions.first.startedAt,
      state.readingSessions.first.startedAt,
    );
  });

  test('zero-length visit updates last read without a fake history item', () {
    final now = DateTime(2026, 2, 3, 12);
    final state = const BookLibraryState().recordReading(
      Duration.zero,
      now: now,
    );

    expect(state.lastReadAt, now);
    expect(state.readingSessions, isEmpty);
  });
}
