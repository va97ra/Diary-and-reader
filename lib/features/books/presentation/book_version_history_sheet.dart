import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_project_version.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum _VersionAction { restore, delete }

class BookVersionHistorySheet extends StatefulWidget {
  const BookVersionHistorySheet({required this.controller, super.key});

  final AuthorWorkspaceController controller;

  @override
  State<BookVersionHistorySheet> createState() =>
      _BookVersionHistorySheetState();
}

class _BookVersionHistorySheetState extends State<BookVersionHistorySheet> {
  late Future<List<BookProjectVersion>> _versions;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _versions = widget.controller.listVersions();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    strings.versionHistory,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  key: const ValueKey('create-version-button'),
                  onPressed: _busy ? null : _createVersion,
                  icon: const Icon(Icons.add),
                  label: Text(strings.createVersion),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(strings.webVersionLimit),
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder<List<BookProjectVersion>>(
              future: _versions,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final versions = snapshot.data ?? const [];
                if (versions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Text(
                          strings.noVersions,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: versions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final version = versions[index];
                    return ListTile(
                      key: ValueKey('book-version-${version.id}'),
                      leading: const CircleAvatar(
                        child: Icon(Icons.history_outlined),
                      ),
                      title: Text(version.label ?? strings.unnamedVersion),
                      subtitle: Text(
                        _formattedDate(context, version.createdAt),
                      ),
                      trailing: PopupMenuButton<_VersionAction>(
                        enabled: !_busy,
                        tooltip: strings.data,
                        onSelected: (action) => _handleAction(version, action),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: _VersionAction.restore,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.restore),
                              title: Text(strings.restoreVersion),
                            ),
                          ),
                          PopupMenuItem(
                            value: _VersionAction.delete,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.delete_outline),
                              title: Text(strings.deleteVersion),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createVersion() async {
    final strings = AppStrings.of(context);
    var enteredLabel = '';
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.createVersion),
        content: TextField(
          key: const ValueKey('version-label-field'),
          autofocus: true,
          decoration: InputDecoration(
            labelText: strings.versionLabel,
            hintText: strings.versionLabelHint,
          ),
          onChanged: (value) => enteredLabel = value,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            key: const ValueKey('confirm-create-version'),
            onPressed: () => Navigator.of(context).pop(enteredLabel),
            child: Text(strings.save),
          ),
        ],
      ),
    );
    if (label == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.controller.createVersion(label: label);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _reload();
      });
      _showMessage(strings.versionCreated);
    } on Exception {
      if (mounted) _showMessage(strings.versionOperationFailed);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  Future<void> _handleAction(
    BookProjectVersion version,
    _VersionAction action,
  ) async {
    switch (action) {
      case _VersionAction.restore:
        return _restore(version);
      case _VersionAction.delete:
        return _delete(version);
    }
  }

  Future<void> _restore(BookProjectVersion version) async {
    final strings = AppStrings.of(context);
    final confirmed = await _confirm(
      title: strings.restoreVersion,
      message: strings.restoreVersionQuestion,
      action: strings.restoreVersion,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.controller.restoreVersion(
        version,
        safetyLabel: strings.safetyVersionLabel,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _reload();
      });
      _showMessage(strings.versionRestored);
    } on Exception {
      if (mounted) _showMessage(strings.versionOperationFailed);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  Future<void> _delete(BookProjectVersion version) async {
    final strings = AppStrings.of(context);
    final confirmed = await _confirm(
      title: strings.deleteVersion,
      message: strings.deleteVersionQuestion,
      action: strings.deleteVersion,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.controller.deleteVersion(version.id);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _reload();
      });
    } on Exception {
      if (mounted) _showMessage(strings.versionOperationFailed);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppStrings.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  String _formattedDate(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final material = MaterialLocalizations.of(context);
    return '${material.formatFullDate(local)} • '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
