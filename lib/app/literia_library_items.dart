part of 'literia_library_page.dart';

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
    final progress = writing ? 0.0 : readingProgress(project);
    final chapterCount = project.sections
        .where((section) => section.type == BookSectionType.chapter)
        .length;
    final wordCount = project.sections.fold(
      0,
      (total, section) =>
          total + ManuscriptStatistics.fromDocument(section.content).words,
    );
    return Card(
      key: ValueKey('literia-project-${project.id}'),
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: Colors.transparent,
      child: BookLeatherPanel(
        child: Theme(
          data: bookLeatherModalTheme(context),
          child: InkWell(
            onTap: onOpen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (writing)
                        const ColoredBox(
                          color: Color(0x5C160C07),
                          child: Icon(
                            Icons.edit_note_outlined,
                            size: 52,
                            color: BookLeatherColors.accent,
                          ),
                        )
                      else
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
                            if (!writing)
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: BookLeatherColors.foreground),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        writing
                            ? '${strings.chapters}: $chapterCount · '
                                  '${strings.words}: $wordCount'
                            : project.metadata.author.trim().isEmpty
                            ? strings.importedBook
                            : project.metadata.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: BookLeatherColors.mutedForeground,
                        ),
                      ),
                      if (writing) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${strings.updated}: ${_shortDate(project.updatedAt)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: BookLeatherColors.mutedForeground,
                              ),
                        ),
                      ],
                      if (!writing) ...[
                        const SizedBox(height: 10),
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress * 100).round()}%',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: BookLeatherColors.mutedForeground,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    final progress = writing ? 0.0 : readingProgress(project);
    final chapterCount = project.sections
        .where((section) => section.type == BookSectionType.chapter)
        .length;
    final wordCount = project.sections.fold(
      0,
      (total, section) =>
          total + ManuscriptStatistics.fromDocument(section.content).words,
    );
    return Card(
      key: ValueKey('literia-project-list-${project.id}'),
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: BookLeatherPanel(
        child: Theme(
          data: bookLeatherModalTheme(context),
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
                  writing
                      ? '${strings.chapters}: $chapterCount · '
                            '${strings.words}: $wordCount'
                      : project.metadata.author.isEmpty
                      ? strings.importedBook
                      : project.metadata.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (writing)
                  Text(
                    '${strings.updated}: ${_shortDate(project.updatedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (project.collectionName.isNotEmpty)
                  Text(
                    project.collectionName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (!writing) LinearProgressIndicator(value: progress),
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
                    if (!writing)
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
        ),
      ),
    );
  }
}

enum _LibraryCardAction { about, collection, readingStatus, delete }

String _shortDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day.$month.${value.year}';
}
