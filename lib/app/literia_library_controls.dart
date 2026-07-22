part of 'literia_library_page.dart';

class _LibraryControls extends StatelessWidget {
  const _LibraryControls({
    required this.writing,
    required this.filter,
    required this.collectionName,
    required this.collections,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onCollectionChanged,
  });

  final bool writing;
  final BookLibraryFilter filter;
  final String? collectionName;
  final List<String> collections;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<BookLibraryFilter> onFilterChanged;
  final ValueChanged<String?> onCollectionChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final filters = writing
        ? const [BookLibraryFilter.all]
        : const [
            BookLibraryFilter.all,
            BookLibraryFilter.unread,
            BookLibraryFilter.inProgress,
            BookLibraryFilter.finished,
            BookLibraryFilter.favorites,
          ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchBar(
            key: const ValueKey('library-search'),
            hintText: strings.librarySearchHint,
            leading: const Icon(Icons.search),
            onChanged: onSearchChanged,
          ),
          if (!writing) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final value in filters) ...[
                    FilterChip(
                      selected: filter == value,
                      label: Text(_filterLabel(strings, value)),
                      onSelected: (_) => onFilterChanged(value),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
          if (collections.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: collectionName,
              decoration: InputDecoration(
                labelText: strings.collectionName,
                isDense: true,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(strings.allCollections),
                ),
                DropdownMenuItem<String?>(
                  value: '',
                  child: Text(strings.noCollection),
                ),
                ...collections.map(
                  (name) =>
                      DropdownMenuItem<String?>(value: name, child: Text(name)),
                ),
              ],
              onChanged: onCollectionChanged,
            ),
          ],
        ],
      ),
    );
  }

  String _filterLabel(AppStrings strings, BookLibraryFilter filter) =>
      switch (filter) {
        BookLibraryFilter.all => strings.allBooks,
        BookLibraryFilter.unread => strings.unreadBooks,
        BookLibraryFilter.inProgress => strings.readingBooks,
        BookLibraryFilter.finished => strings.finishedBooks,
        BookLibraryFilter.favorites => strings.favoriteBooks,
        BookLibraryFilter.manuscripts => strings.manuscripts,
        BookLibraryFilter.imported => strings.importedBooks,
      };
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.writing, required this.filtered});

  final bool writing;
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              writing ? Icons.edit_note_outlined : Icons.auto_stories_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              filtered
                  ? strings.noBooksFound
                  : writing
                  ? strings.emptyManuscripts
                  : strings.emptyReadingLibrary,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String _readingStatusLabel(AppStrings strings, BookReadingStatus status) =>
    switch (status) {
      BookReadingStatus.automatic => strings.statusAutomatic,
      BookReadingStatus.wantToRead => strings.wantToRead,
      BookReadingStatus.reading => strings.readingBooks,
      BookReadingStatus.paused => strings.pausedReading,
      BookReadingStatus.finished => strings.finishedBooks,
    };
