import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_page_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookPropertiesPanel extends StatelessWidget {
  const BookPropertiesPanel({
    required this.controller,
    required this.onChooseCover,
    required this.onRemoveCover,
    super.key,
  });

  final AuthorWorkspaceController controller;
  final Future<void> Function() onChooseCover;
  final VoidCallback onRemoveCover;

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
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
          children: [
            _SettingsCard(
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
                  Row(
                    children: [
                      Expanded(
                        child: _PropertyField(
                          key: ValueKey('${project.id}-subtitle'),
                          label: strings.subtitle,
                          initialValue: metadata.subtitle,
                          onChanged: (value) =>
                              _updateMetadata(metadata, subtitle: value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PropertyField(
                          key: ValueKey('${project.id}-author'),
                          label: strings.author,
                          initialValue: metadata.author,
                          onChanged: (value) =>
                              _updateMetadata(metadata, author: value),
                        ),
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<DraftStatus>(
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
                                  child: Text(
                                    _statusLabel(strings, status),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (status) {
                            if (status != null) {
                              controller.updateSectionStatus(status);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Tooltip(
                          message: strings.writingGoalHint,
                          child: TextFormField(
                            key: ValueKey('${section.id}-word-target'),
                            initialValue: section.targetWords == 0
                                ? ''
                                : section.targetWords.toString(),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(8),
                            ],
                            decoration: InputDecoration(
                              labelText: strings.writingGoal,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) =>
                                controller.updateSectionTargetWords(
                                  int.tryParse(value) ?? 0,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SettingsCard(
              key: const ValueKey('writer-cover-section'),
              title: strings.bookCover,
              child: _CoverSettings(
                coverBytes: project.coverAsset?.bytes,
                onChoose: onChooseCover,
                onRemove: project.coverAsset == null ? null : onRemoveCover,
              ),
            ),
            const SizedBox(height: 8),
            BookPageSettingsSection(controller: controller),
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

class _CoverSettings extends StatelessWidget {
  const _CoverSettings({
    required this.coverBytes,
    required this.onChoose,
    required this.onRemove,
  });

  final Uint8List? coverBytes;
  final Future<void> Function() onChoose;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final hasCover = coverBytes != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          key: const ValueKey('writer-cover-preview'),
          width: 56,
          height: 76,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: hasCover
              ? Image.memory(
                  coverBytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                )
              : const Icon(Icons.auto_stories_outlined, size: 28),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.coverHint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
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
              ),
            ],
          ),
        ),
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
  Widget build(BuildContext context) {
    final field = TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: field);
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    ),
  );
}
