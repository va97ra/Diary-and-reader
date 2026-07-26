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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchBar(
            key: const ValueKey('library-search'),
            constraints: const BoxConstraints(minHeight: 48),
            elevation: const WidgetStatePropertyAll(0),
            hintText: writing
                ? strings.manuscriptLibrarySearchHint
                : strings.librarySearchHint,
            leading: const Icon(Icons.search),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 8),
          _LibraryDisplayControls(
            writing: writing,
            showGrid: showGrid,
            sort: sort,
            onLayoutChanged: onLayoutChanged,
            onSortChanged: onSortChanged,
          ),
          if (!writing) ...[
            const SizedBox(height: 8),
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
    final compact = MediaQuery.sizeOf(context).width < 520;
    final layoutButton = OutlinedButton.icon(
      key: const ValueKey('library-layout-toggle'),
      onPressed: onLayoutChanged,
      icon: Icon(showGrid ? Icons.grid_view : Icons.view_list),
      label: Text(
        compact
            ? showGrid
                  ? strings.gridView
                  : strings.listView
            : '${strings.viewMode}: '
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
          compact
              ? _sortLabel(strings, sort)
              : '${strings.sortBy}: ${_sortLabel(strings, sort)}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    return Row(
      children: [
        Expanded(child: layoutButton),
        const SizedBox(width: 8),
        Expanded(child: sortButton),
      ],
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

class _LibraryPrimaryActions extends StatelessWidget {
  const _LibraryPrimaryActions({
    required this.writing,
    required this.foundDeviceBooks,
    required this.showDeviceAction,
    required this.onPrimaryAction,
    required this.onFindOnDevice,
  });

  final bool writing;
  final int? foundDeviceBooks;
  final bool showDeviceAction;
  final VoidCallback onPrimaryAction;
  final VoidCallback onFindOnDevice;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: writing
          ? BookPanelAction(
              key: const ValueKey('create-manuscript-button'),
              icon: const Icon(Icons.note_add_outlined),
              label: strings.createBook,
              selected: true,
              onPressed: onPrimaryAction,
            )
          : SizedBox(
              height: 72,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: BookPanelAction(
                      key: const ValueKey('import-book-button'),
                      icon: const Icon(Icons.download),
                      label: strings.importBooks,
                      semanticLabel:
                          '${strings.importBooks}. '
                          '${strings.supportedBookFormats}',
                      selected: true,
                      onPressed: onPrimaryAction,
                    ),
                  ),
                  if (showDeviceAction) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: BookPanelAction(
                        key: const ValueKey('find-device-books-button'),
                        icon: const Icon(Icons.folder_open_outlined),
                        label: foundDeviceBooks == null
                            ? strings.findOnDevice
                            : '${strings.findOnDevice}\n'
                                  '${strings.foundOnDevice}: $foundDeviceBooks',
                        compactLabelLines: 2,
                        onPressed: onFindOnDevice,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
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
