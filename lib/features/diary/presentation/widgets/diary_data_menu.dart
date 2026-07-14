import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/diary/application/diary_controller.dart';
import 'package:dnevnik/features/diary/data/diary_file_service.dart';
import 'package:flutter/material.dart';

enum _DataAction { export, import }

class DiaryDataMenu extends StatelessWidget {
  const DiaryDataMenu({
    required this.controller,
    this.fileService = const DiaryFileService(),
    super.key,
  });

  final DiaryController controller;
  final DiaryFileService fileService;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return PopupMenuButton<_DataAction>(
      tooltip: strings.data,
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => _handleAction(context, action),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _DataAction.export,
          child: ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(strings.exportData),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _DataAction.import,
          child: ListTile(
            leading: const Icon(Icons.upload_file_outlined),
            title: Text(strings.importData),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(BuildContext context, _DataAction action) async {
    final strings = AppStrings.of(context);
    if (action == _DataAction.export) {
      await controller.flush();
      final saved = await fileService.saveArchive(controller.exportArchive());
      if (saved && context.mounted) {
        _showMessage(context, strings.exportSuccess);
      }
      return;
    }

    final encoded = await fileService.openArchive();
    if (encoded == null || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.importData),
        content: Text(strings.confirmImport),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.importData),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;
    try {
      await controller.importArchive(encoded);
      if (context.mounted) _showMessage(context, strings.importSuccess);
    } on FormatException {
      if (context.mounted) _showMessage(context, strings.importFailed);
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
