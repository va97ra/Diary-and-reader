import 'package:dnevnik/features/books/domain/book_project.dart';

enum BookLibraryFilter {
  all,
  manuscripts,
  imported,
  unread,
  inProgress,
  finished,
}

enum BookLibrarySort { recentlyUpdated, title, author, progress }

class BookLibraryQuery {
  const BookLibraryQuery({
    this.search = '',
    this.filter = BookLibraryFilter.all,
    this.sort = BookLibrarySort.recentlyUpdated,
    this.collectionName,
  });

  final String search;
  final BookLibraryFilter filter;
  final BookLibrarySort sort;

  /// `null` means every collection; an empty string means ungrouped books.
  final String? collectionName;

  List<BookProject> apply(Iterable<BookProject> projects) {
    final normalizedSearch = search.trim().toLowerCase();
    final result = projects.where((project) {
      if (!_matchesFilter(project) || !_matchesCollection(project)) {
        return false;
      }
      if (normalizedSearch.isEmpty) return true;
      final searchable = [
        project.metadata.title,
        project.metadata.author,
        project.metadata.series,
        project.sourceFileName,
        project.collectionName,
      ].join('\n').toLowerCase();
      return searchable.contains(normalizedSearch);
    }).toList();
    result.sort(_compare);
    return result;
  }

  bool _matchesCollection(BookProject project) =>
      collectionName == null || project.collectionName == collectionName;

  bool _matchesFilter(BookProject project) => switch (filter) {
    BookLibraryFilter.all => true,
    BookLibraryFilter.manuscripts => !project.isReadOnly,
    BookLibraryFilter.imported => project.isReadOnly,
    BookLibraryFilter.unread => readingProgress(project) <= 0.001,
    BookLibraryFilter.inProgress =>
      readingProgress(project) > 0.001 && readingProgress(project) < 0.999,
    BookLibraryFilter.finished => readingProgress(project) >= 0.999,
  };

  int _compare(BookProject left, BookProject right) => switch (sort) {
    BookLibrarySort.recentlyUpdated => right.updatedAt.compareTo(
      left.updatedAt,
    ),
    BookLibrarySort.title => _text(
      left.metadata.title,
    ).compareTo(_text(right.metadata.title)),
    BookLibrarySort.author => _text(
      left.metadata.author,
    ).compareTo(_text(right.metadata.author)),
    BookLibrarySort.progress => readingProgress(
      right,
    ).compareTo(readingProgress(left)),
  };
}

double readingProgress(BookProject project) {
  if (project.sections.isEmpty) return 0;
  final activeIndex = project.sections.indexWhere(
    (section) => section.id == project.readerProgress.sectionId,
  );
  if (activeIndex < 0) return 0;
  return ((activeIndex + project.readerProgress.sectionProgress) /
          project.sections.length)
      .clamp(0, 1)
      .toDouble();
}

String _text(String value) => value.trim().toLowerCase();
