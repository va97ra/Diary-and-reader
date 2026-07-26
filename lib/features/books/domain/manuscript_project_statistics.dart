import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/manuscript_statistics.dart';

class ManuscriptProjectStatistics {
  const ManuscriptProjectStatistics({
    required this.words,
    required this.characters,
    required this.paragraphs,
    required this.completedSections,
  });

  factory ManuscriptProjectStatistics.fromProject(BookProject project) {
    var words = 0;
    var characters = 0;
    var paragraphs = 0;
    var completedSections = 0;
    for (final section in project.sections) {
      final statistics = ManuscriptStatistics.fromDocument(section.content);
      words += statistics.words;
      characters += statistics.characters;
      paragraphs += statistics.paragraphs;
      if (section.status.name == 'complete') completedSections += 1;
    }
    return ManuscriptProjectStatistics(
      words: words,
      characters: characters,
      paragraphs: paragraphs,
      completedSections: completedSections,
    );
  }

  final int words;
  final int characters;
  final int paragraphs;
  final int completedSections;
}
