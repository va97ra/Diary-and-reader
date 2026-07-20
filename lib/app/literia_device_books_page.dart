import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_device_catalog.dart';
import 'package:dnevnik/features/books/application/book_import_coordinator.dart';
import 'package:dnevnik/features/books/domain/book_scan_folder.dart';
import 'package:flutter/material.dart';

class LiteriaDeviceBooksPage extends StatefulWidget {
  const LiteriaDeviceBooksPage({
    required this.controller,
    required this.catalog,
    required this.onImport,
    super.key,
  });

  final AuthorWorkspaceController controller;
  final BookDeviceCatalogGateway catalog;
  final Future<BookImportBatchResult> Function(List<DeviceBookCandidate>)
  onImport;

  @override
  State<LiteriaDeviceBooksPage> createState() => _LiteriaDeviceBooksPageState();
}

class _LiteriaDeviceBooksPageState extends State<LiteriaDeviceBooksPage> {
  DeviceBookScanResult _scanResult = const DeviceBookScanResult();
  final Set<String> _selectedUris = {};
  bool _loading = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final folders = widget.controller.appPreferences.bookScanFolders;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.findOnDevice),
        actions: [
          IconButton(
            tooltip: strings.refresh,
            onPressed: _loading || folders.isEmpty ? null : _scan,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _FolderBar(
            folders: folders,
            inaccessibleUris: _scanResult.inaccessibleFolderUris.toSet(),
            onAdd: _chooseFolder,
            onRemove: _removeFolder,
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(child: _buildBooks(strings, folders)),
        ],
      ),
      bottomNavigationBar: _selectedUris.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  key: const ValueKey('import-selected-device-books'),
                  onPressed: _importing ? null : _importSelected,
                  icon: _importing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.library_add_outlined),
                  label: Text(
                    _importing
                        ? strings.savingBooks
                        : '${strings.addSelected} (${_selectedUris.length})',
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBooks(AppStrings strings, List<BookScanFolder> folders) {
    if (folders.isEmpty) {
      return _EmptyDeviceBooks(
        icon: Icons.create_new_folder_outlined,
        message: strings.noBookFolders,
        actionLabel: strings.addBookFolder,
        onAction: _chooseFolder,
      );
    }
    if (!_loading && _scanResult.books.isEmpty) {
      return _EmptyDeviceBooks(
        icon: Icons.folder_open,
        message: strings.noDeviceBooks,
        actionLabel: strings.refresh,
        onAction: _scan,
      );
    }
    final importedUris = widget.controller.projects
        .where((project) => project.isReadOnly)
        .map((project) => project.sourceExternalUri)
        .where((uri) => uri.isNotEmpty)
        .toSet();
    return ListView.separated(
      key: const ValueKey('device-books-list'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
      itemCount: _scanResult.books.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final book = _scanResult.books[index];
        final imported = importedUris.contains(book.uri);
        return Card(
          margin: EdgeInsets.zero,
          child: CheckboxListTile(
            key: ValueKey('device-book-${book.uri}'),
            value: imported ? true : _selectedUris.contains(book.uri),
            onChanged: imported
                ? null
                : (selected) => setState(() {
                    if (selected ?? false) {
                      _selectedUris.add(book.uri);
                    } else {
                      _selectedUris.remove(book.uri);
                    }
                  }),
            secondary: Icon(
              _iconFor(book.name),
              semanticLabel: imported
                  ? strings.alreadyInLibrary
                  : strings.notAdded,
            ),
            title: Text(
              book.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${book.folderName} · ${formatFileSize(book.sizeBytes)}\n'
              '${imported ? strings.alreadyInLibrary : strings.notAdded}',
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Future<void> _chooseFolder() async {
    final folder = await widget.catalog.chooseFolder();
    if (folder == null || !mounted) return;
    widget.controller.addBookScanFolder(folder);
    await widget.controller.flush();
    if (mounted) await _scan();
  }

  Future<void> _removeFolder(BookScanFolder folder) async {
    await widget.catalog.releaseFolder(folder);
    widget.controller.removeBookScanFolder(folder.uri);
    await widget.controller.flush();
    _selectedUris.removeWhere(
      (uri) => _scanResult.books.any(
        (book) => book.uri == uri && book.folderName == folder.name,
      ),
    );
    if (mounted) await _scan();
  }

  Future<void> _scan() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final result = await widget.catalog.scan(
        widget.controller.appPreferences.bookScanFolders,
      );
      if (!mounted) return;
      setState(() {
        _scanResult = result;
        final available = result.books.map((book) => book.uri).toSet();
        _selectedUris.removeWhere((uri) => !available.contains(uri));
      });
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).bookImportFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importSelected() async {
    setState(() => _importing = true);
    final selected = _scanResult.books
        .where((book) => _selectedUris.contains(book.uri))
        .toList();
    try {
      final result = await widget.onImport(selected);
      if (!mounted) return;
      final strings = AppStrings.of(context);
      final messages = <String>[
        if (result.imported.isNotEmpty)
          '${strings.bookImported}: ${result.imported.length}',
        if (result.duplicateCount > 0)
          '${strings.duplicateBooksSkipped}: ${result.duplicateCount}',
        if (result.failedCount > 0)
          '${strings.someBooksFailed}: ${result.failedCount}',
      ];
      if (messages.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(messages.join(' · '))));
      }
      _selectedUris.clear();
      await _scan();
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  IconData _iconFor(String name) => name.toLowerCase().endsWith('.epub')
      ? Icons.menu_book_outlined
      : Icons.description_outlined;
}

class _FolderBar extends StatelessWidget {
  const _FolderBar({
    required this.folders,
    required this.inaccessibleUris,
    required this.onAdd,
    required this.onRemove,
  });

  final List<BookScanFolder> folders;
  final Set<String> inaccessibleUris;
  final VoidCallback onAdd;
  final ValueChanged<BookScanFolder> onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ActionChip(
              avatar: const Icon(Icons.create_new_folder_outlined),
              label: Text(strings.addBookFolder),
              onPressed: onAdd,
            ),
            for (final folder in folders) ...[
              const SizedBox(width: 8),
              InputChip(
                avatar: Icon(
                  inaccessibleUris.contains(folder.uri)
                      ? Icons.warning_amber
                      : Icons.folder_outlined,
                ),
                label: Text(
                  inaccessibleUris.contains(folder.uri)
                      ? '${folder.name} · ${strings.noAccess}'
                      : folder.name,
                ),
                tooltip: strings.removeFolder,
                onDeleted: () => onRemove(folder),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyDeviceBooks extends StatelessWidget {
  const _EmptyDeviceBooks({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 58, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
          ),
        ],
      ),
    ),
  );
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
  final megabytes = kilobytes / 1024;
  if (megabytes < 1024) return '${megabytes.toStringAsFixed(1)} MB';
  return '${(megabytes / 1024).toStringAsFixed(1)} GB';
}
