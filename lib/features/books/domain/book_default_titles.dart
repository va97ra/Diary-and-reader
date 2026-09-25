import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';

/// Names the app gives new books and sections. Until the author renames
/// them they follow the interface language.
abstract final class BookDefaultTitles {
  static const _languages = ['en', 'ru'];

  static String book(String languageCode) =>
      _english(languageCode) ? 'Untitled book' : 'Новая книга';

  static String firstChapter(String languageCode) =>
      _english(languageCode) ? 'Chapter 1' : 'Глава 1';

  static String section(BookSectionType type, String languageCode) {
    final english = _english(languageCode);
    return switch (type) {
      BookSectionType.part => english ? 'New part' : 'Новая часть',
      BookSectionType.chapter => english ? 'New chapter' : 'Новая глава',
      BookSectionType.scene => english ? 'New scene' : 'Новая сцена',
    };
  }

  /// [project] with its untouched default names in [languageCode]. Imported
  /// books keep their own titles, and nothing counts as an edit.
  static BookProject localize(BookProject project, String languageCode) {
    if (project.isReadOnly) return project;
    final title =
        _translated(project.metadata.title, book, languageCode) ??
        project.metadata.title;
    final sections = [
      for (final section in project.sections)
        _localizedSection(section, languageCode),
    ];
    final sectionsChanged = sections.indexed.any(
      (entry) => !identical(entry.$2, project.sections[entry.$1]),
    );
    if (title == project.metadata.title && !sectionsChanged) return project;
    return project.copyWith(
      metadata: project.metadata.copyWith(title: title),
      sections: sections,
    );
  }

  static BookSection _localizedSection(
    BookSection section,
    String languageCode,
  ) {
    final title =
        _translated(section.title, firstChapter, languageCode) ??
        _translated(
          section.title,
          (language) => BookDefaultTitles.section(section.type, language),
          languageCode,
        );
    return title == null || title == section.title
        ? section
        : section.copyWith(title: title);
  }

  /// [value] in [languageCode] when it is one of the [defaultIn] names.
  static String? _translated(
    String value,
    String Function(String languageCode) defaultIn,
    String languageCode,
  ) => _languages.any((language) => defaultIn(language) == value)
      ? defaultIn(languageCode)
      : null;

  static bool _english(String languageCode) => languageCode == 'en';
}
