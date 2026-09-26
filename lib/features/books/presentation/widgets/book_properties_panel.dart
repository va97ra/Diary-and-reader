import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_page_settings_section.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_settings_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The settings of a manuscript: what the book is, how its pages look, and
/// the progress of the chapter being written.
class BookPropertiesPanel extends StatelessWidget {
  const BookPropertiesPanel({
    required this.controller,
    required this.onChooseCover,
    required this.onRemoveCover,
    required this.a4Preview,
    required this.pagedLayout,
    required this.onToggleA4Preview,
    super.key,
  });

  final AuthorWorkspaceController controller;
  final Future<void> Function() onChooseCover;
  final VoidCallback onRemoveCover;

  /// Whether the editor shows the manuscript as A4 sheets right now.
  final bool a4Preview;

  /// Whether the editor lays text out in pages, where the page view applies.
  final bool pagedLayout;
  final VoidCallback onToggleA4Preview;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = controller.activeProject!;
    final metadata = project.metadata;
    final section = project.activeSection!;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          children: [
            BookSettingsCard(
              key: const ValueKey('writer-properties-section'),
              title: strings.properties,
              child: Column(
                children: [
                  _PropertyField(
                    key: ValueKey('${project.id}-title'),
                    label: strings.bookTitle,
                    initialValue: metadata.title,
                    onChanged: (value) =>
                        _updateMetadata(metadata, title: value),
                  ),
                  BookSettingsRow(
                    children: [
                      _PropertyField(
                        key: ValueKey('${project.id}-subtitle'),
                        label: strings.subtitle,
                        initialValue: metadata.subtitle,
                        onChanged: (value) =>
                            _updateMetadata(metadata, subtitle: value),
                      ),
                      _PropertyField(
                        key: ValueKey('${project.id}-author'),
                        label: strings.author,
                        initialValue: metadata.author,
                        onChanged: (value) =>
                            _updateMetadata(metadata, author: value),
                      ),
                    ],
                  ),
                  _PropertyField(
                    key: ValueKey('${project.id}-description'),
                    label: strings.description,
                    initialValue: metadata.description,
                    maxLines: 3,
                    onChanged: (value) =>
                        _updateMetadata(metadata, description: value),
                  ),
                  _CoverSettings(
                    key: const ValueKey('writer-cover-section'),
                    coverBytes: project.coverAsset?.bytes,
                    onChoose: onChooseCover,
                    onRemove: project.coverAsset == null ? null : onRemoveCover,
                  ),
                ],
              ),
            ),
            BookPageSettingsSection(
              controller: controller,
              a4Preview: a4Preview,
              pagedLayout: pagedLayout,
              onToggleA4Preview: onToggleA4Preview,
            ),
            BookSettingsCard(
              key: const ValueKey('writer-chapter-section'),
              title: strings.chapterSettings,
              hint: strings.chapterSettingsHint,
              child: BookSettingsRow(
                children: [
                  BookCompactDropdown<DraftStatus>(
                    key: ValueKey('${section.id}-status'),
                    label: strings.draftStatus,
                    value: section.status,
                    items: {
                      for (final status in DraftStatus.values)
                        status: _statusLabel(strings, status),
                    },
                    onChanged: controller.updateSectionStatus,
                  ),
                  TextFormField(
                    key: ValueKey('${section.id}-word-target'),
                    initialValue: section.targetWords == 0
                        ? ''
                        : section.targetWords.toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: _denseDecoration(strings.writingGoal),
                    onChanged: (value) => controller.updateSectionTargetWords(
                      int.tryParse(value) ?? 0,
                    ),
                  ),
                ],
              ),
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

/// The outlined field of the settings sheets, as low as their drop-downs.
InputDecoration _denseDecoration(String label) => InputDecoration(
  labelText: label,
  isDense: true,
  border: const OutlineInputBorder(),
  contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
);

class _CoverSettings extends StatelessWidget {
  const _CoverSettings({
    required this.coverBytes,
    required this.onChoose,
    required this.onRemove,
    super.key,
  });

  final Uint8List? coverBytes;
  final Future<void> Function() onChoose;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final hasCover = coverBytes != null;
    return Row(
      children: [
        Container(
          key: const ValueKey('writer-cover-preview'),
          width: 40,
          height: 54,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: hasCover
              ? Image.memory(
                  coverBytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                )
              : const Icon(Icons.auto_stories_outlined, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Tooltip(
            message: strings.coverHint,
            child: OutlinedButton.icon(
              key: const ValueKey('choose-book-cover'),
              onPressed: onChoose,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: Text(
                hasCover ? strings.replaceCover : strings.uploadCover,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        if (hasCover) ...[
          const SizedBox(width: 8),
          IconButton.outlined(
            key: const ValueKey('remove-book-cover'),
            tooltip: strings.removeCover,
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ],
    );
  }
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
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      initialValue: initialValue,
      minLines: 1,
      maxLines: maxLines,
      decoration: _denseDecoration(label),
      onChanged: onChanged,
    ),
  );
}
