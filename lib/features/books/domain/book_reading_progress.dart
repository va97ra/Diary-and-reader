import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';

double bookReadingProgress(
  List<BookSection> sections,
  BookReaderProgress progress,
) {
  if (sections.isEmpty) return 0;

  final activeIndex = sections.indexWhere(
    (section) => section.id == progress.sectionId,
  );
  if (activeIndex < 0) return 0;

  final lengths = sections.map(_readableLength).toList(growable: false);
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
