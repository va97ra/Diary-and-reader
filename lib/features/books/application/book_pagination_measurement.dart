import 'dart:collection';

import 'package:dnevnik/features/books/application/book_page_paginator.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';

class BookPaginationMeasurement {
  BookPaginationMeasurement({required this.maxRetries});

  final int maxRetries;
  final List<RichDocument> _completedPages = [];
  int _retries = 0;

  int get currentPageNumber => _completedPages.length + 1;

  UnmodifiableListView<RichDocument> get completedPages =>
      UnmodifiableListView(_completedPages);

  void begin() {
    _completedPages.clear();
    _retries = 0;
  }

  bool scheduleRetry() => _retries++ < maxRetries;

  void resetRetries() => _retries = 0;

  BookPaginationMeasurementStep advance({
    required RichDocument document,
    required int splitOffset,
    required int lastContentOffset,
  }) {
    final hardPageSplit = BookPagePaginator.splitAtFirstHardPageBreak(
      document,
      splitOffset,
    );
    if (hardPageSplit != null) {
      _completedPages.add(hardPageSplit.visible);
      return BookPaginationMeasurementStep.next(hardPageSplit.overflow);
    }
    if (splitOffset >= lastContentOffset) {
      return BookPaginationMeasurementStep.complete([
        ..._completedPages,
        document,
      ]);
    }
    final split = BookPagePaginator.split(document, splitOffset);
    _completedPages.add(split.visible);
    return BookPaginationMeasurementStep.next(split.overflow);
  }
}

class BookPaginationMeasurementStep {
  const BookPaginationMeasurementStep._({
    this.nextDocument,
    this.completedDocuments,
  });

  factory BookPaginationMeasurementStep.next(RichDocument document) =>
      BookPaginationMeasurementStep._(nextDocument: document);

  factory BookPaginationMeasurementStep.complete(
    List<RichDocument> documents,
  ) => BookPaginationMeasurementStep._(
    completedDocuments: List.unmodifiable(documents),
  );

  final RichDocument? nextDocument;
  final List<RichDocument>? completedDocuments;
}
