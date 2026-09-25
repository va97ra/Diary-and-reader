part of 'literia_library_page.dart';

/// A square icon control that lines up with the search bar. An [active] one
/// is tinted, so a non-default sort or filter stays visible when closed.
ButtonStyle _libraryIconButtonStyle({bool active = false}) {
  final color = active
      ? BookLeatherColors.accent
      : BookLeatherColors.foreground;
  return IconButton.styleFrom(
    fixedSize: const Size.square(44),
    foregroundColor: color,
    side: BorderSide(
      color: active
          ? BookLeatherColors.accent
          : BookLeatherColors.stitch.withValues(alpha: 0.55),
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SearchBar(
                  key: const ValueKey('library-search'),
                  constraints: const BoxConstraints(minHeight: 44),
                  elevation: const WidgetStatePropertyAll(0),
                  hintText: writing
                      ? strings.manuscriptLibrarySearchHint
                      : strings.librarySearchHint,
                  leading: const Icon(Icons.search),
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 4),
              _LibraryDisplayControls(
                writing: writing,
                showGrid: showGrid,
                sort: sort,
                filter: filter,
                onLayoutChanged: onLayoutChanged,
                onSortChanged: onSortChanged,
                onFilterChanged: onFilterChanged,
              ),
            ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Shows the layout a tap switches to.
        IconButton(
          key: const ValueKey('library-layout-toggle'),
          tooltip: showGrid ? strings.listView : strings.gridView,
          style: _libraryIconButtonStyle(),
          onPressed: onLayoutChanged,
          icon: Icon(showGrid ? Icons.view_list : Icons.grid_view),
        ),
        _LibraryMenuButton(
          key: const ValueKey('library-sort-menu'),
          icon: const Icon(Icons.sort),
          tooltip: '${strings.sortBy}: ${_sortLabel(strings, sort)}',
          active: sort != BookLibrarySort.recentlyUpdated,
          values: [
            BookLibrarySort.recentlyUpdated,
            if (!writing) BookLibrarySort.lastRead,
            BookLibrarySort.title,
            BookLibrarySort.author,
            if (!writing) BookLibrarySort.progress,
          ],
          selected: sort,
          labelOf: (value) => _sortLabel(strings, value),
          onSelected: onSortChanged,
        ),
        if (!writing)
          _LibraryMenuButton(
            key: const ValueKey('library-filter-menu'),
            icon: Icon(
              filter == BookLibraryFilter.all
                  ? Icons.filter_alt_outlined
                  : Icons.filter_alt,
            ),
            tooltip: '${strings.filterBooks}: ${_filterLabel(strings, filter)}',
            active: filter != BookLibraryFilter.all,
            values: const [
              BookLibraryFilter.all,
              BookLibraryFilter.unread,
              BookLibraryFilter.inProgress,
              BookLibraryFilter.finished,
              BookLibraryFilter.favorites,
            ],
            selected: filter,
            labelOf: (value) => _filterLabel(strings, value),
            onSelected: onFilterChanged,
          ),
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

/// An icon control that drops a menu of [values] below itself. The menu is a
/// route, so the system back gesture closes it and not the library.
class _LibraryMenuButton<T> extends StatelessWidget {
  const _LibraryMenuButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    super.key,
  });

  final Widget icon;
  final String tooltip;
  final bool active;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;

  Future<void> _openMenu(BuildContext context) async {
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final value = await showMenu<T>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          button.localToGlobal(
            button.size.bottomLeft(Offset.zero),
            ancestor: overlay,
          ),
          button.localToGlobal(
            button.size.bottomRight(Offset.zero),
            ancestor: overlay,
          ),
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        for (final value in values)
          CheckedPopupMenuItem(
            value: value,
            checked: value == selected,
            child: Text(labelOf(value)),
          ),
      ],
    );
    if (value != null) onSelected(value);
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    style: _libraryIconButtonStyle(active: active),
    onPressed: () => _openMenu(context),
    icon: icon,
  );
}

/// The library's main action, floating above the books.
class _LibraryPrimaryAction extends StatelessWidget {
  const _LibraryPrimaryAction({required this.writing, required this.onPressed});

  final bool writing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return FloatingActionButton.extended(
      key: ValueKey(
        writing ? 'create-manuscript-button' : 'import-book-button',
      ),
      tooltip: writing ? null : strings.supportedBookFormats,
      onPressed: onPressed,
      backgroundColor: BookLeatherColors.accent,
      foregroundColor: BookLeatherColors.backgroundDark,
      icon: Icon(writing ? Icons.note_add_outlined : Icons.download),
      label: Text(writing ? strings.createBook : strings.importBooks),
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
