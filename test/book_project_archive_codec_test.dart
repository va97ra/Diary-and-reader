import 'package:dnevnik/features/books/application/book_project_archive_codec.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips a complete book project', () {
    final project = BookProject.create(
      title: 'Переносимая книга',
      chapterTitle: 'Начало',
      languageCode: 'ru',
    );

    final restored = BookProjectArchiveCodec.decode(
      BookProjectArchiveCodec.encode(project),
    );

    expect(restored.metadata.title, 'Переносимая книга');
    expect(restored.sections.single.title, 'Начало');
    expect(restored.id, project.id);
  });

  test('rejects unrelated and unsupported archives', () {
    expect(
      () => BookProjectArchiveCodec.decode('{"format":"other"}'),
      throwsFormatException,
    );
    expect(
      () => BookProjectArchiveCodec.decode(
        '{"format":"dnevnik-book-project","version":99,"project":{}}',
      ),
      throwsFormatException,
    );
  });
}
