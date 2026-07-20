import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_library_query.dart';
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
    this.onFindOnDevice,
    this.countDeviceBooks,
    super.key,
  });

  final LiteriaLibraryMode mode;
  final AuthorWorkspaceController controller;
  final Future<void> Function() onPrimaryAction;
  final Future<void> Function(BookProject project) onOpen;
  final Future<void> Function(BookProject project) onDelete;
  final Future<void> Function()? onFindOnDevice;
  final Future<int> Function()? countDeviceBooks;

  @override
  State<LiteriaLibraryPage> createState() => _LiteriaLibraryPageState();
}

class _LiteriaLibraryPageState extends State<LiteriaLibraryPage> {
  int? _foundDeviceBooks;

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
        final projects =
            widget.controller.projects
                .where(
                  (project) =>
                      _writing ? !project.isReadOnly : project.isReadOnly,
                )
                .toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        return _buildPage(context, projects);
      },
    );
  }

  Widget _buildPage(BuildContext context, List<BookProject> projects) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _writing ? strings.manuscriptLibrary : strings.readingLibrary,
        ),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          key: ValueKey(_writing ? 'manuscript-library' : 'reading-library'),
          slivers: [
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
                child: _EmptyLibrary(writing: _writing),
              )
            else
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
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.writing});

  final bool writing;

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
              writing ? strings.emptyManuscripts : strings.emptyReadingLibrary,
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
  });

  final BookProject project;
  final bool writing;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

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
                    right: 8,
                    child: PopupMenuButton<_LibraryCardAction>(
                      tooltip: strings.more,
                      onSelected: (action) {
                        if (action == _LibraryCardAction.delete) onDelete();
                      },
                      itemBuilder: (_) => [
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

enum _LibraryCardAction { delete }
