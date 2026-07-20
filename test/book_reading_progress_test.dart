import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_reading_progress.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weights reading progress by readable section length', () {
    final project = BookProject.create(
      title: 'Книга',
      chapterTitle: 'Короткая',
    );
    final shortSection = project.sections.single.copyWith(
      content: const [
        {'insert': '1234567890\n'},
      ],
    );
    final longSection =
        BookSection.create(
          id: 'long-section',
          title: 'Длинная',
          type: BookSectionType.chapter,
        ).copyWith(
          content: const [
            {'insert': '123456789012345678901234567890\n'},
          ],
        );
    final sections = [shortSection, longSection];

    expect(
      bookReadingProgress(
        sections,
        BookReaderProgress(sectionId: longSection.id),
      ),
      closeTo(0.25, 0.0001),
    );
    expect(
      bookReadingProgress(
        sections,
        BookReaderProgress(sectionId: longSection.id, sectionProgress: 0.5),
      ),
      closeTo(0.625, 0.0001),
    );
  });

  test('falls back to section order when every section is empty', () {
    final project = BookProject.create(title: 'Книга', chapterTitle: 'Первая');
    final secondSection = BookSection.create(
      id: 'second-section',
      title: 'Вторая',
      type: BookSectionType.chapter,
    );
    final sections = [project.sections.single, secondSection];

    expect(
      bookReadingProgress(
        sections,
        BookReaderProgress(sectionId: secondSection.id, sectionProgress: 0.5),
      ),
      0.75,
    );
    expect(
      bookReadingProgress(
        sections,
        const BookReaderProgress(sectionId: 'missing'),
      ),
      0,
    );
  });
}
