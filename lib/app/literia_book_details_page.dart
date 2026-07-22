import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_library_query.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_cover_view.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_metadata_editor_dialog.dart';
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
      appBar: AppBar(
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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: BookCoverView(
              project: project,
              width: 180,
              height: 260,
              borderRadius: 14,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            metadata.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (metadata.author.isNotEmpty)
            Text(
              metadata.author,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('read-from-book-details'),
            onPressed: () => onRead(project),
            icon: const Icon(Icons.menu_book_outlined),
            label: Text(strings.read),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('edit-book-metadata'),
            onPressed: () => _editMetadata(context, metadata),
            icon: const Icon(Icons.edit_outlined),
            label: Text(strings.editMetadata),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 6),
          Text('${strings.readingProgress}: ${(progress * 100).round()}%'),
          _detail(
            context,
            strings.readingTime,
            _formatDuration(project.libraryState.readingTimeSeconds),
          ),
          if (lastReadAt != null)
            _detail(
              context,
              strings.lastRead,
              MaterialLocalizations.of(context).formatMediumDate(lastReadAt),
            ),
          if (metadata.series.isNotEmpty)
            _detail(context, strings.series, metadata.series),
          if (metadata.genre.isNotEmpty)
            _detail(context, strings.genre, metadata.genre),
          if (metadata.isbn.isNotEmpty)
            _detail(context, strings.isbn, metadata.isbn),
          if (metadata.publisher.isNotEmpty)
            _detail(context, strings.publisher, metadata.publisher),
          if (metadata.description.isNotEmpty)
            _detail(context, strings.description, metadata.description),
        ],
      ),
    );
  }

  Widget _detail(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 3),
        SelectableText(value),
      ],
    ),
  );

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

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '$minutes мин';
    return '$hours ч $minutes мин';
  }
}
