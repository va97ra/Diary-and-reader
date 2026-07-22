import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_library_query.dart';
import 'package:dnevnik/features/books/domain/book_library_state.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_cover_view.dart';
import 'package:flutter/material.dart';

enum LiteriaLibraryMode { manuscripts, reading }

class LiteriaLibraryPage extends StatefulWidget {
  const LiteriaLibraryPage({
    required this.mode,
    required this.controller,
    required this.onPrimaryAction,
    required this.onOpen,
    required this.onDelete,
    required this.onAbout,
    this.onFindOnDevice,
    this.countDeviceBooks,
    super.key,
  });

  final LiteriaLibraryMode mode;
  final AuthorWorkspaceController controller;
  final Future<void> Function() onPrimaryAction;
  final Future<void> Function(BookProject project) onOpen;
  final Future<void> Function(BookProject project) onDelete;
  final Future<void> Function(BookProject project) onAbout;
  final Future<void> Function()? onFindOnDevice;
  final Future<int> Function()? countDeviceBooks;

  @override
  State<LiteriaLibraryPage> createState() => _LiteriaLibraryPageState();
}

class _LiteriaLibraryPageState extends State<LiteriaLibraryPage> {
  int? _foundDeviceBooks;
  bool _showGrid = true;
  String _search = '';
  BookLibraryFilter _filter = BookLibraryFilter.all;
  BookLibrarySort _sort = BookLibrarySort.recentlyUpdated;
  String? _collectionName;

  bool get _writing => widget.mode == LiteriaLibraryMode.manuscripts;

  @override
  void initState() {
    super.initState();
    if (!_writing) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _refreshDeviceCount(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final availableProjects = widget.controller.projects
            .where(
              (project) => _writing ? !project.isReadOnly : project.isReadOnly,
            )
            .toList();
        final projects = BookLibraryQuery(
          search: _search,
          filter: _filter,
          sort: _sort,
          collectionName: _collectionName,
        ).apply(availableProjects);
        final collections =
            availableProjects
                .map((project) => project.collectionName.trim())
                .where((name) => name.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        return _buildPage(context, projects, collections);
      },
    );
  }

  Widget _buildPage(
    BuildContext context,
    List<BookProject> projects,
    List<String> collections,
  ) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _writing ? strings.manuscriptLibrary : strings.readingLibrary,
        ),
        actions: [
          IconButton(
            key: const ValueKey('library-layout-toggle'),
            tooltip: _showGrid ? strings.listView : strings.gridView,
            onPressed: () => setState(() => _showGrid = !_showGrid),
            icon: Icon(_showGrid ? Icons.view_list : Icons.grid_view),
          ),
          PopupMenuButton<BookLibrarySort>(
            tooltip: strings.sortBy,
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: BookLibrarySort.recentlyUpdated,
                child: Text(strings.recentlyUpdated),
              ),
              if (!_writing)
                PopupMenuItem(
                  value: BookLibrarySort.lastRead,
                  child: Text(strings.byLastRead),
                ),
              PopupMenuItem(
                value: BookLibrarySort.title,
                child: Text(strings.byTitle),
              ),
              PopupMenuItem(
                value: BookLibrarySort.author,
                child: Text(strings.byAuthor),
              ),
              if (!_writing)
                PopupMenuItem(
                  value: BookLibrarySort.progress,
                  child: Text(strings.byProgress),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          key: ValueKey(_writing ? 'manuscript-library' : 'reading-library'),
          slivers: [
            SliverToBoxAdapter(
              child: _LibraryControls(
                writing: _writing,
                filter: _filter,
                collectionName: _collectionName,
                collections: collections,
                onSearchChanged: (value) => setState(() => _search = value),
                onFilterChanged: (value) => setState(() => _filter = value),
                onCollectionChanged: (value) =>
                    setState(() => _collectionName = value),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: FilledButton.icon(
                  key: ValueKey(
                    _writing
                        ? 'create-manuscript-button'
                        : 'import-book-button',
                  ),
                  onPressed: widget.onPrimaryAction,
                  icon: Icon(
                    _writing ? Icons.note_add_outlined : Icons.download,
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _writing ? strings.createBook : strings.importBooks,
                        ),
                        if (!_writing)
                          Text(
                            strings.supportedBookFormats,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!_writing && widget.onFindOnDevice != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: OutlinedButton.icon(
                    key: const ValueKey('find-device-books-button'),
                    onPressed: _openDeviceBooks,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(strings.findOnDevice),
                          if (_foundDeviceBooks != null)
                            Text(
                              '${strings.foundOnDevice}: $_foundDeviceBooks',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (projects.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyLibrary(
                  writing: _writing,
                  filtered:
                      _search.trim().isNotEmpty ||
                      _filter != BookLibraryFilter.all ||
                      _collectionName != null,
                ),
              )
            else if (_showGrid)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 230,
                    mainAxisExtent: 320,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _LibraryCard(
                      project: project,
                      writing: _writing,
                      onOpen: () => widget.onOpen(project),
                      onDelete: () => widget.onDelete(project),
                      onMoveToCollection: () => _showCollectionDialog(project),
                      onToggleFavorite: () => _toggleFavorite(project),
                      onChangeReadingStatus: () =>
                          _showReadingStatusDialog(project),
                      onAbout: () => widget.onAbout(project),
                    );
                  },
                ),
              ),
            if (projects.isNotEmpty && !_showGrid)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
                sliver: SliverList.separated(
                  itemCount: projects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _LibraryListTile(
                      project: project,
                      writing: _writing,
                      onOpen: () => widget.onOpen(project),
                      onDelete: () => widget.onDelete(project),
                      onMoveToCollection: () => _showCollectionDialog(project),
                      onToggleFavorite: () => _toggleFavorite(project),
                      onChangeReadingStatus: () =>
                          _showReadingStatusDialog(project),
                      onAbout: () => widget.onAbout(project),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDeviceBooks() async {
    await widget.onFindOnDevice?.call();
    await _refreshDeviceCount();
  }

  Future<void> _refreshDeviceCount() async {
    try {
      final count = await widget.countDeviceBooks?.call();
      if (mounted && count != null) setState(() => _foundDeviceBooks = count);
    } on Exception {
      if (mounted) setState(() => _foundDeviceBooks = null);
    }
  }

  Future<void> _showCollectionDialog(BookProject project) async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController(text: project.collectionName);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.moveToCollection),
        content: TextField(
          key: const ValueKey('library-collection-field'),
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: strings.collectionName,
            hintText: strings.collectionHint,
          ),
          onSubmitted: (text) => Navigator.pop(dialogContext, text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.cancel),
          ),
          if (project.collectionName.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, ''),
              child: Text(strings.removeFromCollection),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(strings.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    widget.controller.updateProjectCollection(project.id, value);
    await widget.controller.flush();
  }

  void _toggleFavorite(BookProject project) {
    widget.controller.updateProjectFavorite(
      project.id,
      !project.libraryState.isFavorite,
    );
  }

  Future<void> _showReadingStatusDialog(BookProject project) async {
    final strings = AppStrings.of(context);
    final status = await showDialog<BookReadingStatus>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(strings.readingStatus),
        children: [
          RadioGroup<BookReadingStatus>(
            groupValue: project.libraryState.readingStatus,
            onChanged: (selected) {
              if (selected != null) Navigator.pop(dialogContext, selected);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final value in BookReadingStatus.values)
                  RadioListTile<BookReadingStatus>(
                    value: value,
                    title: Text(_readingStatusLabel(strings, value)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (status == null) return;
    widget.controller.updateProjectReadingStatus(project.id, status);
    await widget.controller.flush();
  }
}

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

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({
    required this.project,
    required this.writing,
    required this.onOpen,
    required this.onDelete,
    required this.onMoveToCollection,
    required this.onToggleFavorite,
    required this.onChangeReadingStatus,
    required this.onAbout,
  });

  final BookProject project;
  final bool writing;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onMoveToCollection;
  final VoidCallback onToggleFavorite;
  final VoidCallback onChangeReadingStatus;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      key: ValueKey('literia-project-${project.id}'),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BookCoverView(
                    project: project,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 0,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton.filledTonal(
                      tooltip: strings.favoriteBooks,
                      onPressed: onToggleFavorite,
                      icon: Icon(
                        project.libraryState.isFavorite
                            ? Icons.star
                            : Icons.star_border,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: PopupMenuButton<_LibraryCardAction>(
                      tooltip: strings.more,
                      onSelected: (action) {
                        switch (action) {
                          case _LibraryCardAction.collection:
                            onMoveToCollection();
                          case _LibraryCardAction.readingStatus:
                            onChangeReadingStatus();
                          case _LibraryCardAction.about:
                            onAbout();
                          case _LibraryCardAction.delete:
                            onDelete();
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: _LibraryCardAction.about,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.info_outline),
                            title: Text(strings.aboutBook),
                          ),
                        ),
                        PopupMenuItem(
                          value: _LibraryCardAction.readingStatus,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.flag_outlined),
                            title: Text(strings.readingStatus),
                          ),
                        ),
                        PopupMenuItem(
                          value: _LibraryCardAction.collection,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.folder_outlined),
                            title: Text(strings.moveToCollection),
                          ),
                        ),
                        PopupMenuItem(
                          value: _LibraryCardAction.delete,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.delete_outline),
                            title: Text(strings.deleteBook),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.metadata.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    project.metadata.author.trim().isEmpty
                        ? (writing ? strings.manuscript : strings.importedBook)
                        : project.metadata.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (!writing) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: readingProgress(project)),
                    const SizedBox(height: 4),
                    Text(
                      '${(readingProgress(project) * 100).round()}%',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryListTile extends StatelessWidget {
  const _LibraryListTile({
    required this.project,
    required this.writing,
    required this.onOpen,
    required this.onDelete,
    required this.onMoveToCollection,
    required this.onToggleFavorite,
    required this.onChangeReadingStatus,
    required this.onAbout,
  });

  final BookProject project;
  final bool writing;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onMoveToCollection;
  final VoidCallback onToggleFavorite;
  final VoidCallback onChangeReadingStatus;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      key: ValueKey('literia-project-list-${project.id}'),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onOpen,
        minTileHeight: 104,
        leading: BookCoverView(
          project: project,
          width: 62,
          height: 88,
          borderRadius: 6,
        ),
        title: Text(project.metadata.title, maxLines: 2),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              project.metadata.author.isEmpty
                  ? (writing ? strings.manuscript : strings.importedBook)
                  : project.metadata.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (project.collectionName.isNotEmpty)
              Text(
                project.collectionName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (!writing)
              LinearProgressIndicator(value: readingProgress(project)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: strings.favoriteBooks,
              onPressed: onToggleFavorite,
              icon: Icon(
                project.libraryState.isFavorite
                    ? Icons.star
                    : Icons.star_border,
              ),
            ),
            PopupMenuButton<_LibraryCardAction>(
              tooltip: strings.more,
              onSelected: (action) => switch (action) {
                _LibraryCardAction.collection => onMoveToCollection(),
                _LibraryCardAction.readingStatus => onChangeReadingStatus(),
                _LibraryCardAction.about => onAbout(),
                _LibraryCardAction.delete => onDelete(),
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _LibraryCardAction.about,
                  child: Text(strings.aboutBook),
                ),
                PopupMenuItem(
                  value: _LibraryCardAction.collection,
                  child: Text(strings.moveToCollection),
                ),
                PopupMenuItem(
                  value: _LibraryCardAction.readingStatus,
                  child: Text(strings.readingStatus),
                ),
                PopupMenuItem(
                  value: _LibraryCardAction.delete,
                  child: Text(strings.deleteBook),
                ),
              ],
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

enum _LibraryCardAction { about, collection, readingStatus, delete }
