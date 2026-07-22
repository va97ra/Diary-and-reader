import 'package:dnevnik/features/books/domain/book_library_state.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reading_progress.dart';

enum BookLibraryFilter {
  all,
  manuscripts,
  imported,
  unread,
  inProgress,
  finished,
  favorites,
}

enum BookLibrarySort { recentlyUpdated, lastRead, title, author, progress }

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
    BookLibraryFilter.unread =>
      effectiveReadingStatus(project) == BookReadingStatus.wantToRead,
    BookLibraryFilter.inProgress =>
      effectiveReadingStatus(project) == BookReadingStatus.reading ||
          effectiveReadingStatus(project) == BookReadingStatus.paused,
    BookLibraryFilter.finished =>
      effectiveReadingStatus(project) == BookReadingStatus.finished,
    BookLibraryFilter.favorites => project.libraryState.isFavorite,
  };

  int _compare(BookProject left, BookProject right) => switch (sort) {
    BookLibrarySort.recentlyUpdated => right.updatedAt.compareTo(
      left.updatedAt,
    ),
    BookLibrarySort.lastRead => _lastRead(right).compareTo(_lastRead(left)),
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

BookReadingStatus effectiveReadingStatus(BookProject project) {
  final explicit = project.libraryState.readingStatus;
  if (explicit != BookReadingStatus.automatic) return explicit;
  final progress = readingProgress(project);
  if (progress >= 0.999) return BookReadingStatus.finished;
  if (progress > 0.001) return BookReadingStatus.reading;
  return BookReadingStatus.wantToRead;
}

double readingProgress(BookProject project) {
  return bookReadingProgress(project.sections, project.readerProgress);
}

String _text(String value) => value.trim().toLowerCase();

DateTime _lastRead(BookProject project) =>
    project.libraryState.lastReadAt ?? DateTime.fromMillisecondsSinceEpoch(0);
