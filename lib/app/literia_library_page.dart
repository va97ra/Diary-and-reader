import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_library_query.dart';
import 'package:dnevnik/features/books/domain/book_library_state.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/manuscript_statistics.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_adaptive_control_shell.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_cover_view.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:flutter/material.dart';

part 'literia_library_controls.dart';
part 'literia_library_items.dart';

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
        foregroundColor: BookLeatherColors.foreground,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: const BookLeatherPanel(
          safeArea: EdgeInsets.only(top: 1, left: 1, right: 1),
          child: SizedBox.expand(),
        ),
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
              child: BookLeatherPanel(
                key: const ValueKey('library-control-panel'),
                safeArea: const EdgeInsets.only(left: 1, right: 1),
                child: Theme(
                  data: bookLeatherModalTheme(context),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LibraryControls(
                        writing: _writing,
                        filter: _filter,
                        collectionName: _collectionName,
                        collections: collections,
                        showGrid: _showGrid,
                        sort: _sort,
                        onSearchChanged: (value) =>
                            setState(() => _search = value),
                        onLayoutChanged: () =>
                            setState(() => _showGrid = !_showGrid),
                        onSortChanged: (value) => setState(() => _sort = value),
                        onFilterChanged: (value) =>
                            setState(() => _filter = value),
                        onCollectionChanged: (value) =>
                            setState(() => _collectionName = value),
                      ),
                      _LibraryPrimaryActions(
                        writing: _writing,
                        foundDeviceBooks: _foundDeviceBooks,
                        showDeviceAction: widget.onFindOnDevice != null,
                        onPrimaryAction: widget.onPrimaryAction,
                        onFindOnDevice: _openDeviceBooks,
                      ),
                    ],
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
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 230,
                    mainAxisExtent: _writing ? 196 : 320,
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
      builder: (dialogContext) => BookLeatherDialog(
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
      builder: (dialogContext) => BookLeatherDialog(
        title: Text(strings.readingStatus),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
    if (status == null) return;
    widget.controller.updateProjectReadingStatus(project.id, status);
    await widget.controller.flush();
  }
}
