import 'package:dnevnik/features/books/application/book_pagination_measurement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('collects pages until the remaining document fits', () {
    final measurement = BookPaginationMeasurement(maxRetries: 2)..begin();
    final source = [
      {'insert': 'Первая часть. Вторая часть.\n'},
    ];

    final first = measurement.advance(
      document: source,
      splitOffset: 14,
      lastContentOffset: 27,
    );
    expect(first.nextDocument, isNotNull);
    expect(measurement.currentPageNumber, 2);

    final second = measurement.advance(
      document: first.nextDocument!,
      splitOffset: 100,
      lastContentOffset: 13,
    );
    expect(second.completedDocuments, hasLength(2));
  });

  test('bounds render retries for a measurement pass', () {
    final measurement = BookPaginationMeasurement(maxRetries: 2)..begin();

    expect(measurement.scheduleRetry(), isTrue);
    expect(measurement.scheduleRetry(), isTrue);
    expect(measurement.scheduleRetry(), isFalse);

    measurement.resetRetries();
    expect(measurement.scheduleRetry(), isTrue);
  });
}
