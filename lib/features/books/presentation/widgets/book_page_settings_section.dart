import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_page_view_mode_selector.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_setting_number_field.dart';
import 'package:flutter/material.dart';

class BookPageSettingsSection extends StatelessWidget {
  const BookPageSettingsSection({required this.controller, super.key});

  final AuthorWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = controller.activeProject!;
    final settings = project.layoutSettings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.pageLayout,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text('${strings.paperFormat}: A4'),
        const SizedBox(height: 14),
        BookPageViewModeSelector(
          value: settings.viewMode,
          onChanged: (viewMode) =>
              _update(settings.copyWith(viewMode: viewMode)),
        ),
        const SizedBox(height: 18),
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
          selected: {settings.orientation},
          onSelectionChanged: (selection) =>
              _update(settings.copyWith(orientation: selection.single)),
        ),
        const SizedBox(height: 18),
        Text(strings.margins, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _MarginPreset(
              label: strings.narrow,
              selected: _allMarginsEqual(settings, 12.7),
              onSelected: () => _uniform(settings, 12.7),
            ),
            _MarginPreset(
              label: strings.normal,
              selected: _allMarginsEqual(settings, 20),
              onSelected: () => _uniform(settings, 20),
            ),
            _MarginPreset(
              label: strings.wide,
              selected: _allMarginsEqual(settings, 25.4),
              onSelected: () => _uniform(settings, 25.4),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BookSettingNumberField(
                key: ValueKey('${project.id}-margin-top'),
                label: strings.top,
                value: settings.marginTopMm,
                minimum: 5,
                maximum: 50,
                suffix: strings.millimeters,
                onChanged: (value) =>
                    _update(settings.copyWith(marginTopMm: value)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BookSettingNumberField(
                key: ValueKey('${project.id}-margin-bottom'),
                label: strings.bottom,
                value: settings.marginBottomMm,
                minimum: 5,
                maximum: 50,
                suffix: strings.millimeters,
                onChanged: (value) =>
                    _update(settings.copyWith(marginBottomMm: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: BookSettingNumberField(
                key: ValueKey('${project.id}-margin-left'),
                label: strings.left,
                value: settings.marginLeftMm,
                minimum: 5,
                maximum: 50,
                suffix: strings.millimeters,
                onChanged: (value) =>
                    _update(settings.copyWith(marginLeftMm: value)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BookSettingNumberField(
                key: ValueKey('${project.id}-margin-right'),
                label: strings.right,
                value: settings.marginRightMm,
                minimum: 5,
                maximum: 50,
                suffix: strings.millimeters,
                onChanged: (value) =>
                    _update(settings.copyWith(marginRightMm: value)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _uniform(BookLayoutSettings settings, double value) =>
      _update(settings.withUniformMargins(value));

  void _update(BookLayoutSettings settings) =>
      controller.updateLayoutSettings(settings);

  bool _allMarginsEqual(BookLayoutSettings settings, double value) =>
      (settings.marginTopMm - value).abs() < 0.01 &&
      (settings.marginRightMm - value).abs() < 0.01 &&
      (settings.marginBottomMm - value).abs() < 0.01 &&
      (settings.marginLeftMm - value).abs() < 0.01;
}

class _MarginPreset extends StatelessWidget {
  const _MarginPreset({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onSelected(),
  );
}
