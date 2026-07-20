import 'package:dnevnik/app/literia_device_books_page.dart';
import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_device_catalog.dart';
import 'package:dnevnik/features/books/application/book_source_storage.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:flutter/material.dart';

enum _StorageSort { size, title, lastRead }

class LiteriaBookStoragePage extends StatefulWidget {
  const LiteriaBookStoragePage({
    required this.controller,
    required this.sourceStorage,
    required this.deviceCatalog,
    super.key,
  });

  final AuthorWorkspaceController controller;
  final BookSourceStorage sourceStorage;
  final BookDeviceCatalogGateway deviceCatalog;

  @override
  State<LiteriaBookStoragePage> createState() => _LiteriaBookStoragePageState();
}

class _LiteriaBookStoragePageState extends State<LiteriaBookStoragePage> {
  BookStorageOverview? _overview;
  final Set<String> _selectedIds = {};
  _StorageSort _sort = _StorageSort.size;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final overview = _overview;
    final entries = [...?overview?.entries]..sort(_compareEntries);
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(strings.bookStorage),
        ),
      ),
      body: overview == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              key: const ValueKey('book-storage-list'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _StorageSummary(overview: overview),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<_StorageSort>(
                        initialValue: _sort,
                        decoration: InputDecoration(
                          labelText: strings.sortBy,
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: _StorageSort.size,
                            child: Text(strings.bySize),
                          ),
                          DropdownMenuItem(
                            value: _StorageSort.title,
                            child: Text(strings.byTitle),
                          ),
                          DropdownMenuItem(
                            value: _StorageSort.lastRead,
                            child: Text(strings.byLastRead),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _sort = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: strings.refresh,
                      onPressed: _busy ? null : _reload,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      strings.emptyReadingLibrary,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final entry in entries)
                    _StorageBookTile(
                      entry: entry,
                      selected: _selectedIds.contains(entry.project.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedIds.add(entry.project.id);
                        } else {
                          _selectedIds.remove(entry.project.id);
                        }
                      }),
                    ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const ValueKey('delete-stored-originals'),
                  onPressed: _busy || !_hasSelectedOriginal(entries)
                      ? null
                      : _deleteOriginals,
                  icon: const Icon(Icons.file_download_off_outlined),
                  label: Text(strings.deleteStoredOriginal),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  key: const ValueKey('delete-books-completely'),
                  onPressed: _busy || _selectedIds.isEmpty
                      ? null
                      : _deleteBooks,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(strings.deleteBooksCompletely),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _busy ? null : _cleanupTemporaryFiles,
                  icon: const Icon(Icons.cleaning_services_outlined),
                  label: Text(strings.clearTemporaryFiles),
                ),
              ],
            ),
    );
  }

  int _compareEntries(BookStorageEntry a, BookStorageEntry b) =>
      switch (_sort) {
        _StorageSort.size => b.totalBytes.compareTo(a.totalBytes),
        _StorageSort.title => a.project.metadata.title.toLowerCase().compareTo(
          b.project.metadata.title.toLowerCase(),
        ),
        _StorageSort.lastRead => b.project.updatedAt.compareTo(
          a.project.updatedAt,
        ),
      };

  bool _hasSelectedOriginal(List<BookStorageEntry> entries) => entries.any(
    (entry) =>
        _selectedIds.contains(entry.project.id) && entry.hasStoredOriginal,
  );

  Future<void> _reload() async {
    setState(() => _busy = true);
    try {
      final available = await widget.deviceCatalog.availableBytes();
      final overview = await widget.sourceStorage.inspect(
        widget.controller.projects,
        availableBytes: available,
      );
      if (!mounted) return;
      setState(() {
        _overview = overview;
        final ids = overview.entries.map((entry) => entry.project.id).toSet();
        _selectedIds.removeWhere((id) => !ids.contains(id));
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteOriginals() async {
    final strings = AppStrings.of(context);
    if (!await _confirm(
      strings.deleteStoredOriginal,
      strings.originalDeleteWarning,
    )) {
      return;
    }
    final targets = _selectedProjects()
        .where((project) => project.sourceStoredPath.isNotEmpty)
        .toList();
    setState(() => _busy = true);
    for (final project in targets) {
      widget.controller.clearImportedBookStoredSource(project.id);
    }
    await widget.controller.flush();
    for (final project in targets) {
      await widget.sourceStorage.deleteOriginal(project);
    }
    _selectedIds.clear();
    if (!mounted) return;
    _showMessage(strings.originalFilesDeleted);
    await _reload();
  }

  Future<void> _deleteBooks() async {
    final strings = AppStrings.of(context);
    if (!await _confirm(
      strings.deleteBooksCompletely,
      strings.completeDeleteWarning,
    )) {
      return;
    }
    final targets = _selectedProjects().toList();
    setState(() => _busy = true);
    for (final project in targets) {
      widget.controller.deleteProject(project.id);
    }
    await widget.controller.flush();
    for (final project in targets) {
      await widget.sourceStorage.deleteProjectFiles(project);
    }
    _selectedIds.clear();
    if (!mounted) return;
    _showMessage(strings.booksDeleted);
    await _reload();
  }

  Future<void> _cleanupTemporaryFiles() async {
    final strings = AppStrings.of(context);
    setState(() => _busy = true);
    await widget.sourceStorage.cleanup(widget.controller.projects);
    if (!mounted) return;
    _showMessage(strings.temporaryFilesCleared);
    await _reload();
  }

  Iterable<BookProject> _selectedProjects() => widget.controller.projects.where(
    (project) => _selectedIds.contains(project.id),
  );

  Future<bool> _confirm(String title, String body) async =>
      (await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(AppStrings.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(title),
            ),
          ],
        ),
      )) ??
      false;

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _StorageSummary extends StatelessWidget {
  const _StorageSummary({required this.overview});

  final BookStorageOverview overview;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final items = <(IconData, String, int?)>[
      (Icons.storage_outlined, strings.totalBookData, overview.totalBytes),
      (Icons.archive_outlined, strings.storedOriginals, overview.originalBytes),
      (
        Icons.auto_stories_outlined,
        strings.processedBooks,
        overview.processedBytes,
      ),
      (Icons.sd_storage_outlined, strings.freeSpace, overview.availableBytes),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
                  width: 150,
                  child: Row(
                    children: [
                      Icon(item.$1),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              item.$3 == null ? '—' : formatFileSize(item.$3!),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _StorageBookTile extends StatelessWidget {
  const _StorageBookTile({
    required this.entry,
    required this.selected,
    required this.onSelected,
  });

  final BookStorageEntry entry;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: selected,
        onChanged: (value) => onSelected(value ?? false),
        title: Text(entry.project.metadata.title),
        subtitle: Text(
          '${formatFileSize(entry.totalBytes)} · '
          '${entry.hasStoredOriginal ? strings.storedOriginal : strings.originalNotStored}',
        ),
        secondary: Icon(
          entry.hasStoredOriginal
              ? Icons.inventory_2_outlined
              : Icons.menu_book_outlined,
        ),
      ),
    );
  }
}
