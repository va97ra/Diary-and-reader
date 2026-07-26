part of 'literia_library_page.dart';

class _LibraryControls extends StatelessWidget {
  const _LibraryControls({
    required this.writing,
    required this.filter,
    required this.collectionName,
    required this.collections,
    required this.showGrid,
    required this.sort,
    required this.onSearchChanged,
    required this.onLayoutChanged,
    required this.onSortChanged,
    required this.onFilterChanged,
    required this.onCollectionChanged,
  });

  final bool writing;
  final BookLibraryFilter filter;
  final String? collectionName;
  final List<String> collections;
  final bool showGrid;
  final BookLibrarySort sort;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onLayoutChanged;
  final ValueChanged<BookLibrarySort> onSortChanged;
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
            hintText: writing
                ? strings.manuscriptLibrarySearchHint
                : strings.librarySearchHint,
            leading: const Icon(Icons.search),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 10),
          _LibraryDisplayControls(
            writing: writing,
            showGrid: showGrid,
            sort: sort,
            onLayoutChanged: onLayoutChanged,
            onSortChanged: onSortChanged,
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

class _LibraryDisplayControls extends StatelessWidget {
  const _LibraryDisplayControls({
    required this.writing,
    required this.showGrid,
    required this.sort,
    required this.onLayoutChanged,
    required this.onSortChanged,
  });

  final bool writing;
  final bool showGrid;
  final BookLibrarySort sort;
  final VoidCallback onLayoutChanged;
  final ValueChanged<BookLibrarySort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final layoutButton = OutlinedButton.icon(
      key: const ValueKey('library-layout-toggle'),
      onPressed: onLayoutChanged,
      icon: Icon(showGrid ? Icons.grid_view : Icons.view_list),
      label: Text(
        '${strings.viewMode}: '
        '${showGrid ? strings.gridView : strings.listView}',
        overflow: TextOverflow.ellipsis,
      ),
    );
    final sortButton = MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed: () => onSortChanged(BookLibrarySort.recentlyUpdated),
          child: Text(strings.recentlyUpdated),
        ),
        if (!writing)
          MenuItemButton(
            onPressed: () => onSortChanged(BookLibrarySort.lastRead),
            child: Text(strings.byLastRead),
          ),
        MenuItemButton(
          onPressed: () => onSortChanged(BookLibrarySort.title),
          child: Text(strings.byTitle),
        ),
        MenuItemButton(
          onPressed: () => onSortChanged(BookLibrarySort.author),
          child: Text(strings.byAuthor),
        ),
        if (!writing)
          MenuItemButton(
            onPressed: () => onSortChanged(BookLibrarySort.progress),
            child: Text(strings.byProgress),
          ),
      ],
      builder: (context, controller, _) => OutlinedButton.icon(
        key: const ValueKey('library-sort-menu'),
        onPressed: controller.isOpen ? controller.close : controller.open,
        icon: const Icon(Icons.sort),
        label: Text(
          '${strings.sortBy}: ${_sortLabel(strings, sort)}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [layoutButton, const SizedBox(height: 8), sortButton],
          );
        }
        return Row(
          children: [
            Expanded(child: layoutButton),
            const SizedBox(width: 8),
            Expanded(child: sortButton),
          ],
        );
      },
    );
  }

  String _sortLabel(AppStrings strings, BookLibrarySort value) =>
      switch (value) {
        BookLibrarySort.recentlyUpdated => strings.recentlyUpdated,
        BookLibrarySort.lastRead => strings.byLastRead,
        BookLibrarySort.title => strings.byTitle,
        BookLibrarySort.author => strings.byAuthor,
        BookLibrarySort.progress => strings.byProgress,
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
