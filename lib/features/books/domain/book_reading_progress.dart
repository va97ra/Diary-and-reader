import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';

double bookReadingProgress(
  List<BookSection> sections,
  BookReaderProgress progress,
) => bookReadingProgressForLengths(
  sections,
  bookSectionReadableLengths(sections),
  progress,
);

/// Measuring a chapter walks its whole text, so readers that ask for progress
/// repeatedly measure once and pass the lengths back in.
List<int> bookSectionReadableLengths(List<BookSection> sections) =>
    sections.map(_readableLength).toList(growable: false);

double bookReadingProgressForLengths(
  List<BookSection> sections,
  List<int> lengths,
  BookReaderProgress progress,
) {
  if (sections.isEmpty) return 0;

  final activeIndex = sections.indexWhere(
    (section) => section.id == progress.sectionId,
  );
  if (activeIndex < 0) return 0;
  final totalLength = lengths.fold<int>(0, (total, length) => total + length);
  final sectionProgress = progress.sectionProgress.clamp(0, 1).toDouble();

  if (totalLength <= 0) {
    return ((activeIndex + sectionProgress) / sections.length)
        .clamp(0, 1)
        .toDouble();
  }

  final completedLength = lengths
      .take(activeIndex)
      .fold<int>(0, (total, length) => total + length);
  final currentLength = lengths[activeIndex];
  return ((completedLength + currentLength * sectionProgress) / totalLength)
      .clamp(0, 1)
      .toDouble();
}

int _readableLength(BookSection section) =>
    richDocumentPlainText(section.content).trim().length;
