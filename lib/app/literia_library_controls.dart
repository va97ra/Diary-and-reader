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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchBar(
            key: const ValueKey('library-search'),
            constraints: const BoxConstraints(minHeight: 44),
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
            filter: filter,
            onLayoutChanged: onLayoutChanged,
            onSortChanged: onSortChanged,
            onFilterChanged: onFilterChanged,
          ),
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
}

class _LibraryDisplayControls extends StatelessWidget {
  const _LibraryDisplayControls({
    required this.writing,
    required this.showGrid,
    required this.sort,
    required this.filter,
    required this.onLayoutChanged,
    required this.onSortChanged,
    required this.onFilterChanged,
  });

  final bool writing;
  final bool showGrid;
  final BookLibrarySort sort;
  final BookLibraryFilter filter;
  final VoidCallback onLayoutChanged;
  final ValueChanged<BookLibrarySort> onSortChanged;
  final ValueChanged<BookLibraryFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      textStyle: const TextStyle(fontSize: 10.5, height: 1.08),
    );
    final layoutButton = OutlinedButton.icon(
      key: const ValueKey('library-layout-toggle'),
      onPressed: onLayoutChanged,
      style: buttonStyle,
      icon: Icon(showGrid ? Icons.grid_view : Icons.view_list, size: 17),
      label: _LibraryControlLabel(
        showGrid ? strings.gridView : strings.listView,
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
        style: buttonStyle,
        icon: const Icon(Icons.sort, size: 17),
        label: _LibraryControlLabel(_sortLabel(strings, sort)),
      ),
    );
    final filterButton = MenuAnchor(
      menuChildren: [
        for (final value in const [
          BookLibraryFilter.all,
          BookLibraryFilter.unread,
          BookLibraryFilter.inProgress,
          BookLibraryFilter.finished,
          BookLibraryFilter.favorites,
        ])
          MenuItemButton(
            onPressed: () => onFilterChanged(value),
            leadingIcon: Icon(filter == value ? Icons.check : null, size: 18),
            child: Text(_filterLabel(strings, value)),
          ),
      ],
      builder: (context, controller, _) => OutlinedButton.icon(
        key: const ValueKey('library-filter-menu'),
        onPressed: controller.isOpen ? controller.close : controller.open,
        style: buttonStyle,
        icon: Icon(
          filter == BookLibraryFilter.all
              ? Icons.filter_alt_outlined
              : Icons.filter_alt,
          size: 17,
        ),
        label: _LibraryControlLabel(strings.filterBooks),
      ),
    );
    return Row(
      children: [
        Expanded(child: layoutButton),
        const SizedBox(width: 8),
        Expanded(child: sortButton),
        if (!writing) ...[
          const SizedBox(width: 8),
          Expanded(child: filterButton),
        ],
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

class _LibraryControlLabel extends StatelessWidget {
  const _LibraryControlLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 2,
    softWrap: true,
    textAlign: TextAlign.center,
    overflow: TextOverflow.visible,
  );
}

class _LibraryPrimaryActions extends StatelessWidget {
  const _LibraryPrimaryActions({
    required this.writing,
    required this.scanning,
    required this.showScanAction,
    required this.onPrimaryAction,
    required this.onScan,
  });

  final bool writing;
  final bool scanning;
  final bool showScanAction;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onScan;

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
              height: 64,
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
                  if (showScanAction) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: BookPanelAction(
                        key: const ValueKey('scan-device-books-button'),
                        icon: scanning
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.manage_search_outlined),
                        label: scanning
                            ? strings.scanningBooks
                            : strings.scanBooks,
                        onPressed: onScan,
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
