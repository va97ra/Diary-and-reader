import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter/material.dart';

class BookPropertiesPanel extends StatelessWidget {
  const BookPropertiesPanel({required this.controller, super.key});

  final AuthorWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = controller.activeProject!;
    final metadata = project.metadata;
    final section = project.activeSection!;
    return Material(
      color: AppTheme.surface,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              strings.properties,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _PropertyField(
              key: ValueKey('${project.id}-title'),
              label: strings.bookTitle,
              initialValue: metadata.title,
              onChanged: (value) => _updateMetadata(metadata, title: value),
            ),
            _PropertyField(
              key: ValueKey('${project.id}-subtitle'),
              label: strings.subtitle,
              initialValue: metadata.subtitle,
              onChanged: (value) => _updateMetadata(metadata, subtitle: value),
            ),
            _PropertyField(
              key: ValueKey('${project.id}-author'),
              label: strings.author,
              initialValue: metadata.author,
              onChanged: (value) => _updateMetadata(metadata, author: value),
            ),
            _PropertyField(
              key: ValueKey('${project.id}-description'),
              label: strings.description,
              initialValue: metadata.description,
              maxLines: 4,
              onChanged: (value) =>
                  _updateMetadata(metadata, description: value),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<DraftStatus>(
              initialValue: section.status,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: strings.draftStatus,
                border: const OutlineInputBorder(),
              ),
              items: DraftStatus.values
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(_statusLabel(strings, status)),
                    ),
                  )
                  .toList(),
              onChanged: (status) {
                if (status != null) controller.updateSectionStatus(status);
              },
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              strings.pageLayout,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text('${strings.paperFormat}: A4'),
            const SizedBox(height: 4),
            Text(
              '${strings.margins}: 20 ${strings.millimeters}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Text(
              strings.orientation,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<BookPageOrientation>(
              key: ValueKey('${project.id}-page-orientation'),
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: BookPageOrientation.portrait,
                  icon: const Icon(Icons.stay_current_portrait),
                  label: Text(strings.portrait),
                ),
                ButtonSegment(
                  value: BookPageOrientation.landscape,
                  icon: const Icon(Icons.stay_current_landscape),
                  label: Text(strings.landscape),
                ),
              ],
              selected: {project.layoutSettings.orientation},
              onSelectionChanged: (selection) {
                controller.updateLayoutSettings(
                  project.layoutSettings.copyWith(
                    orientation: selection.single,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateMetadata(
    BookMetadata metadata, {
    String? title,
    String? subtitle,
    String? author,
    String? description,
  }) {
    controller.updateMetadata(
      metadata.copyWith(
        title: title,
        subtitle: subtitle,
        author: author,
        description: description,
      ),
    );
  }

  String _statusLabel(AppStrings strings, DraftStatus status) =>
      switch (status) {
        DraftStatus.planned => strings.planned,
        DraftStatus.draft => strings.draft,
        DraftStatus.revision => strings.revision,
        DraftStatus.complete => strings.complete,
      };
}

class _PropertyField extends StatelessWidget {
  const _PropertyField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.maxLines = 1,
    super.key,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    ),
  );
}
