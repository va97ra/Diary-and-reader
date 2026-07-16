import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_library_query.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_cover_view.dart';
import 'package:flutter/material.dart';

class BookLibraryBrowser extends StatefulWidget {
  const BookLibraryBrowser({
    required this.controller,
    this.onImportBook,
    super.key,
  });

  final AuthorWorkspaceController controller;
  final VoidCallback? onImportBook;

  static Future<bool> show(
    BuildContext context, {
    required AuthorWorkspaceController controller,
    VoidCallback? onImportBook,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final compact = MediaQuery.sizeOf(dialogContext).width < 700;
          final content = BookLibraryBrowser(
            controller: controller,
            onImportBook: onImportBook,
          );
          if (compact) return Dialog.fullscreen(child: content);
          return Dialog(
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1180,
                maxHeight: 820,
                minWidth: 760,
                minHeight: 560,
              ),
              child: content,
            ),
          );
        },
      ) ??
      false;

  @override
  State<BookLibraryBrowser> createState() => _BookLibraryBrowserState();
}

class _BookLibraryBrowserState extends State<BookLibraryBrowser> {
  final _searchController = TextEditingController();
  BookLibraryFilter _filter = BookLibraryFilter.all;
  BookLibrarySort _sort = BookLibrarySort.recentlyUpdated;
  String? _collectionName;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final strings = AppStrings.of(context);
      final projects = widget.controller.projects;
      final collections =
          projects
              .map((project) => project.collectionName)
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList()
            ..sort(
              (left, right) =>
                  left.toLowerCase().compareTo(right.toLowerCase()),
            );
      final books = BookLibraryQuery(
        search: _searchController.text,
        filter: _filter,
        sort: _sort,
        collectionName: _collectionName,
      ).apply(projects);

      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(strings.library),
          actions: [
            IconButton(
              key: const ValueKey('library-new-book'),
              tooltip: strings.newBook,
              onPressed: widget.controller.addProject,
              icon: const Icon(Icons.note_add_outlined),
            ),
            if (widget.onImportBook != null)
              IconButton(
                key: const ValueKey('library-import-book'),
                tooltip: strings.importEbook,
                onPressed: widget.onImportBook,
                icon: const Icon(Icons.file_download_outlined),
              ),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _LibraryControls(
                searchController: _searchController,
                filter: _filter,
                sort: _sort,
                collectionName: _collectionName,
                collections: collections,
                onSearchChanged: (_) => setState(() {}),
                onFilterChanged: (value) => setState(() => _filter = value),
                onSortChanged: (value) => setState(() => _sort = value),
                onCollectionChanged: (value) =>
                    setState(() => _collectionName = value),
              ),
              Expanded(
                child: books.isEmpty
                    ? _EmptyLibrary(searching: projects.isNotEmpty)
                    : GridView.builder(
                        key: const ValueKey('library-book-grid'),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 230,
                              mainAxisExtent: 330,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: books.length,
                        itemBuilder: (context, index) => _BookLibraryCard(
                          project: books[index],
                          progress: readingProgress(books[index]),
                          onSelected: () {
                            widget.controller.selectProject(books[index].id);
                            Navigator.pop(context, true);
                          },
                          onCollection: () => _editCollection(
                            books[index],
                            collections: collections,
                          ),
                          onDelete: () => _deleteBook(books[index]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Future<void> _editCollection(
    BookProject project, {
    required List<String> collections,
  }) async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController(text: project.collectionName);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.moveToCollection),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const ValueKey('library-collection-field'),
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: strings.collectionName,
                  hintText: strings.collectionHint,
                ),
                onSubmitted: (value) => Navigator.pop(dialogContext, value),
              ),
              if (collections.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: collections
                      .map(
                        (name) => ActionChip(
                          label: Text(name),
                          onPressed: () => Navigator.pop(dialogContext, name),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
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
    if (result != null) {
      widget.controller.updateProjectCollection(project.id, result);
    }
  }

  Future<void> _deleteBook(BookProject project) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteBook),
        content: Text(strings.deleteBookQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.deleteBook),
          ),
        ],
      ),
    );
    if (confirmed ?? false) widget.controller.deleteProject(project.id);
  }
}

class _LibraryControls extends StatelessWidget {
  const _LibraryControls({
    required this.searchController,
    required this.filter,
    required this.sort,
    required this.collectionName,
    required this.collections,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onCollectionChanged,
  });

  final TextEditingController searchController;
  final BookLibraryFilter filter;
  final BookLibrarySort sort;
  final String? collectionName;
  final List<String> collections;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<BookLibraryFilter> onFilterChanged;
  final ValueChanged<BookLibrarySort> onSortChanged;
  final ValueChanged<String?> onCollectionChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final search = TextField(
                key: const ValueKey('library-search-field'),
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: strings.librarySearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              );
              final sortField = DropdownButtonFormField<BookLibrarySort>(
                key: const ValueKey('library-sort-field'),
                initialValue: sort,
                decoration: InputDecoration(labelText: strings.sortBy),
                items: BookLibrarySort.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_sortLabel(strings, value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onSortChanged(value);
                },
              );
              if (constraints.maxWidth < 620) {
                return Column(
                  children: [search, const SizedBox(height: 10), sortField],
                );
              }
              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 12),
                  SizedBox(width: 220, child: sortField),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final value in BookLibraryFilter.values) ...[
                  FilterChip(
                    label: Text(_filterLabel(strings, value)),
                    selected: filter == value,
                    onSelected: (_) => onFilterChanged(value),
                  ),
                  const SizedBox(width: 8),
                ],
                const SizedBox(width: 4),
                DropdownButton<String?>(
                  key: const ValueKey('library-collection-filter'),
                  value: collectionName,
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(strings.allCollections),
                    ),
                    DropdownMenuItem(
                      value: '',
                      child: Text(strings.noCollection),
                    ),
                    ...collections.map(
                      (name) =>
                          DropdownMenuItem(value: name, child: Text(name)),
                    ),
                  ],
                  onChanged: onCollectionChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookLibraryCard extends StatelessWidget {
  const _BookLibraryCard({
    required this.project,
    required this.progress,
    required this.onSelected,
    required this.onCollection,
    required this.onDelete,
  });

  final BookProject project;
  final double progress;
  final VoidCallback onSelected;
  final VoidCallback onCollection;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey('library-book-${project.id}'),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onSelected,
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
                    top: 6,
                    right: 6,
                    child: Material(
                      color: colors.surface.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: PopupMenuButton<_CardAction>(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).showMenuTooltip,
                        onSelected: (action) => switch (action) {
                          _CardAction.collection => onCollection(),
                          _CardAction.delete => onDelete(),
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: _CardAction.collection,
                            child: Text(strings.moveToCollection),
                          ),
                          PopupMenuItem(
                            value: _CardAction.delete,
                            child: Text(strings.deleteBook),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.metadata.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    project.metadata.author.trim().isEmpty
                        ? (project.isReadOnly
                              ? strings.importedBook
                              : strings.manuscript)
                        : project.metadata.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (project.collectionName.isNotEmpty)
                    Text(
                      project.collectionName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: colors.primary),
                    ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress, minHeight: 4),
                  const SizedBox(height: 4),
                  Text(
                    '${strings.readingProgress}: ${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_stories_outlined, size: 56),
          const SizedBox(height: 12),
          Text(
            searching
                ? AppStrings.of(context).noBooksFound
                : AppStrings.of(context).emptyLibrary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

String _filterLabel(AppStrings strings, BookLibraryFilter filter) =>
    switch (filter) {
      BookLibraryFilter.all => strings.allBooks,
      BookLibraryFilter.manuscripts => strings.manuscripts,
      BookLibraryFilter.imported => strings.importedBooks,
      BookLibraryFilter.unread => strings.unreadBooks,
      BookLibraryFilter.inProgress => strings.readingBooks,
      BookLibraryFilter.finished => strings.finishedBooks,
    };

String _sortLabel(AppStrings strings, BookLibrarySort sort) => switch (sort) {
  BookLibrarySort.recentlyUpdated => strings.recentlyUpdated,
  BookLibrarySort.title => strings.byTitle,
  BookLibrarySort.author => strings.byAuthor,
  BookLibrarySort.progress => strings.byProgress,
};

enum _CardAction { collection, delete }
