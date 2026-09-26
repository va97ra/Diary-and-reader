import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_library_query.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_adaptive_control_shell.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_cover_view.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_metadata_editor_dialog.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_settings_controls.dart';
import 'package:flutter/material.dart';

class LiteriaBookDetailsPage extends StatelessWidget {
  const LiteriaBookDetailsPage({
    required this.projectId,
    required this.controller,
    required this.onRead,
    super.key,
  });

  final String projectId;
  final AuthorWorkspaceController controller;
  final Future<void> Function(BookProject project) onRead;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final project = controller.projects
          .where((candidate) => candidate.id == projectId)
          .firstOrNull;
      if (project == null) return const SizedBox.shrink();
      return _BookDetailsBody(
        project: project,
        controller: controller,
        onRead: onRead,
      );
    },
  );
}

class _BookDetailsBody extends StatelessWidget {
  const _BookDetailsBody({
    required this.project,
    required this.controller,
    required this.onRead,
  });

  final BookProject project;
  final AuthorWorkspaceController controller;
  final Future<void> Function(BookProject project) onRead;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final metadata = project.metadata;
    final progress = readingProgress(project);
    final lastReadAt = project.libraryState.lastReadAt;
    return Scaffold(
      appBar: LiteriaLeatherAppBar(
        title: Text(strings.aboutBook),
        actions: [
          IconButton(
            tooltip: strings.favoriteBooks,
            onPressed: () => controller.updateProjectFavorite(
              project.id,
              !project.libraryState.isFavorite,
            ),
            icon: Icon(
              project.libraryState.isFavorite ? Icons.star : Icons.star_border,
            ),
          ),
        ],
      ),
      body: LiteriaParchmentBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
          children: [
            Center(
              child: BookCoverView(
                project: project,
                width: 150,
                height: 216,
                borderRadius: 12,
              ),
            ),
            const SizedBox(height: 12),
            Theme(
              data: bookLeatherModalTheme(context),
              child: LiteriaLeatherCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      metadata.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: BookLeatherColors.foreground,
                        fontFamily: 'PT Serif',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (metadata.author.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        metadata.author,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: BookLeatherColors.mutedForeground,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            key: const ValueKey('read-from-book-details'),
                            onPressed: () => onRead(project),
                            icon: const Icon(Icons.menu_book_outlined),
                            label: Text(strings.read),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('edit-book-metadata'),
                            onPressed: () => _editMetadata(context, metadata),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(
                              strings.editShort,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            _LeatherSection(
              child: BookSettingsCard(
                key: const ValueKey('book-details-reading'),
                title: strings.readingProgress,
                icon: Icons.auto_stories_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${(progress * 100).round()}%'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BookSettingsRow(
                      children: [
                        _Fact(
                          label: strings.readingTime,
                          value: _formatDuration(
                            strings,
                            project.libraryState.readingTimeSeconds,
                          ),
                        ),
                        _Fact(
                          label: strings.lastRead,
                          value: lastReadAt == null
                              ? '—'
                              : MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(lastReadAt),
                        ),
                      ],
                    ),
                    if (project.libraryState.readingSessions.isNotEmpty)
                      Theme(
                        data: Theme.of(
                          context,
                        ).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: const ValueKey('book-details-history'),
                          tilePadding: EdgeInsets.zero,
                          dense: true,
                          textColor: BookLeatherColors.foreground,
                          collapsedTextColor: BookLeatherColors.foreground,
                          iconColor: BookLeatherColors.accent,
                          collapsedIconColor: BookLeatherColors.accent,
                          title: Text(strings.readingHistory),
                          children: [
                            for (final session
                                in project.libraryState.readingSessions.take(5))
                              _Fact(
                                label: MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(session.startedAt),
                                value: _formatDuration(
                                  strings,
                                  session.durationSeconds,
                                ),
                                inline: true,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if ([
              metadata.series,
              metadata.genre,
              metadata.isbn,
              metadata.publisher,
              metadata.description,
            ].any((value) => value.isNotEmpty))
              _LeatherSection(
                child: BookSettingsCard(
                  key: const ValueKey('book-details-about'),
                  title: strings.aboutBook,
                  icon: Icons.info_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (label, value) in [
                        (strings.series, metadata.series),
                        (strings.genre, metadata.genre),
                        (strings.isbn, metadata.isbn),
                        (strings.publisher, metadata.publisher),
                        (strings.description, metadata.description),
                      ])
                        if (value.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _Fact(label: label, value: value),
                          ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMetadata(
    BuildContext context,
    BookMetadata metadata,
  ) async {
    final updated = await showDialog<BookMetadata>(
      context: context,
      builder: (_) => BookMetadataEditorDialog(metadata: metadata),
    );
    if (updated == null) return;
    controller.updateProjectMetadata(project.id, updated);
    await controller.flush();
  }

  String _formatDuration(AppStrings strings, int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes =
        '${duration.inMinutes.remainder(60)} ${strings.minutesShort}';
    return hours == 0 ? minutes : '$hours ${strings.hoursShort} $minutes';
  }
}

/// A section of the page on the leather of the book's title card.
class _LeatherSection extends StatelessWidget {
  const _LeatherSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    // The card of the section lies flat on the leather.
    child: Theme(
      data: bookLeatherModalTheme(context).copyWith(
        cardTheme: const CardThemeData(
          color: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(),
        ),
      ),
      child: LiteriaLeatherCard(padding: EdgeInsets.zero, child: child),
    ),
  );
}

/// A fact about the book with its name above it, or beside it when [inline].
class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value, this.inline = false});

  final String label;
  final String value;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: BookLeatherColors.mutedForeground);
    const valueStyle = TextStyle(color: BookLeatherColors.foreground);
    if (inline) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: labelStyle)),
            Text(value, style: valueStyle),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 2),
        SelectableText(value, style: valueStyle),
      ],
    );
  }
}
