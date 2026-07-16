import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

enum BookProjectDataAction { history, backup, restore }

enum BookCompactWorkspaceAction {
  search,
  export,
  properties,
  history,
  backup,
  restore,
  language,
}

class BookWorkspaceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const BookWorkspaceAppBar({
    required this.bookTitle,
    required this.sectionTitle,
    required this.isDesktop,
    required this.isTablet,
    required this.isA4Preview,
    required this.languageCode,
    required this.onFocusMode,
    required this.onToggleA4Preview,
    required this.onSearch,
    required this.onExport,
    required this.onOpenReader,
    required this.onProjectDataAction,
    required this.onCompactAction,
    required this.onToggleLanguage,
    required this.onProperties,
    super.key,
  });

  final String bookTitle;
  final String sectionTitle;
  final bool isDesktop;
  final bool isTablet;
  final bool isA4Preview;
  final String languageCode;
  final VoidCallback onFocusMode;
  final VoidCallback onToggleA4Preview;
  final VoidCallback onSearch;
  final VoidCallback onExport;
  final VoidCallback onOpenReader;
  final ValueChanged<BookProjectDataAction> onProjectDataAction;
  final ValueChanged<BookCompactWorkspaceAction> onCompactAction;
  final VoidCallback onToggleLanguage;
  final VoidCallback onProperties;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AppBar(
      titleSpacing: isTablet ? 20 : 12,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bookTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            sectionTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        if (isTablet)
          IconButton(
            key: const ValueKey('manuscript-search-button'),
            tooltip: strings.findAndReplace,
            onPressed: onSearch,
            icon: const Icon(Icons.manage_search),
          ),
        IconButton(
          key: const ValueKey('editor-focus-mode-button'),
          tooltip: strings.focusWriting,
          onPressed: onFocusMode,
          icon: const Icon(Icons.fullscreen),
        ),
        if (!isTablet)
          IconButton(
            key: const ValueKey('mobile-a4-preview-button'),
            tooltip: isA4Preview
                ? strings.comfortableWriting
                : strings.a4Preview,
            onPressed: onToggleA4Preview,
            icon: Icon(
              isA4Preview
                  ? Icons.edit_note_outlined
                  : Icons.description_outlined,
            ),
          ),
        if (isTablet)
          IconButton(
            key: const ValueKey('export-book-button'),
            tooltip: strings.exportBook,
            onPressed: onExport,
            icon: const Icon(Icons.ios_share_outlined),
          ),
        IconButton(
          key: const ValueKey('open-book-reader'),
          tooltip: strings.reader,
          onPressed: onOpenReader,
          icon: const Icon(Icons.chrome_reader_mode_outlined),
        ),
        if (isTablet) ...[
          _ProjectDataMenu(strings: strings, onSelected: onProjectDataAction),
          IconButton(
            tooltip: strings.language,
            onPressed: onToggleLanguage,
            icon: Text(languageCode.toUpperCase()),
          ),
          if (!isDesktop)
            IconButton(
              tooltip: strings.properties,
              onPressed: onProperties,
              icon: const Icon(Icons.tune),
            ),
        ] else
          _CompactWorkspaceMenu(strings: strings, onSelected: onCompactAction),
      ],
    );
  }
}

class _ProjectDataMenu extends StatelessWidget {
  const _ProjectDataMenu({required this.strings, required this.onSelected});

  final AppStrings strings;
  final ValueChanged<BookProjectDataAction> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<BookProjectDataAction>(
    key: const ValueKey('project-data-menu'),
    tooltip: strings.projectData,
    icon: const Icon(Icons.more_vert),
    onSelected: onSelected,
    itemBuilder: (_) => [
      _menuItem(
        BookProjectDataAction.history,
        Icons.history,
        strings.versionHistory,
      ),
      _menuItem(
        BookProjectDataAction.backup,
        Icons.download_outlined,
        strings.backupProject,
      ),
      _menuItem(
        BookProjectDataAction.restore,
        Icons.upload_file_outlined,
        strings.restoreProjectBackup,
      ),
    ],
  );
}

class _CompactWorkspaceMenu extends StatelessWidget {
  const _CompactWorkspaceMenu({
    required this.strings,
    required this.onSelected,
  });

  final AppStrings strings;
  final ValueChanged<BookCompactWorkspaceAction> onSelected;

  @override
  Widget build(BuildContext context) =>
      PopupMenuButton<BookCompactWorkspaceAction>(
        key: const ValueKey('mobile-workspace-menu'),
        tooltip: strings.moreActions,
        onSelected: onSelected,
        itemBuilder: (_) => [
          _menuItem(
            BookCompactWorkspaceAction.search,
            Icons.manage_search,
            strings.findAndReplace,
          ),
          _menuItem(
            BookCompactWorkspaceAction.export,
            Icons.ios_share_outlined,
            strings.exportBook,
          ),
          _menuItem(
            BookCompactWorkspaceAction.properties,
            Icons.tune,
            strings.properties,
          ),
          _menuItem(
            BookCompactWorkspaceAction.history,
            Icons.history,
            strings.versionHistory,
          ),
          _menuItem(
            BookCompactWorkspaceAction.backup,
            Icons.download_outlined,
            strings.backupProject,
          ),
          _menuItem(
            BookCompactWorkspaceAction.restore,
            Icons.upload_file_outlined,
            strings.restoreProjectBackup,
          ),
          _menuItem(
            BookCompactWorkspaceAction.language,
            Icons.language,
            strings.language,
          ),
        ],
      );
}

PopupMenuItem<T> _menuItem<T>(T value, IconData icon, String label) =>
    PopupMenuItem(
      value: value,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(label),
      ),
    );
