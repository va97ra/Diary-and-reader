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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => _buildSettings(context),
  );

  Widget _buildSettings(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = controller.activeProject!;
    final settings = project.layoutSettings;
    final marginPreset = _uniformMarginPreset(settings);
    return Card(
      key: const ValueKey('writer-page-layout-section'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.pageLayout,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 108,
                  child: _ReadOnlySettingValue(
                    label: strings.paperFormatShort,
                    value: 'A4',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.orientation,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<BookPageOrientation>(
                          key: ValueKey('${project.id}-page-orientation'),
                          showSelectedIcon: false,
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.symmetric(horizontal: 6),
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          segments: [
                            ButtonSegment(
                              value: BookPageOrientation.portrait,
                              label: Text(
                                strings.portrait,
                                key: const ValueKey(
                                  'page-orientation-portrait',
                                ),
                              ),
                            ),
                            ButtonSegment(
                              value: BookPageOrientation.landscape,
                              label: Text(
                                strings.landscape,
                                key: const ValueKey(
                                  'page-orientation-landscape',
                                ),
                              ),
                            ),
                          ],
                          selected: {settings.orientation},
                          onSelectionChanged: (selection) => _update(
                            settings.copyWith(orientation: selection.single),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              key: ValueKey('${project.id}-show-chapter-titles'),
              contentPadding: EdgeInsets.zero,
              visualDensity: const VisualDensity(vertical: -3),
              title: Text(
                strings.showChapterTitlesInBody,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(
                strings.showChapterTitlesInBodyHint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              value: settings.showChapterTitlesInBody,
              onChanged: (value) =>
                  _update(settings.copyWith(showChapterTitlesInBody: value)),
            ),
            const SizedBox(height: 6),
            BookPageViewModeSelector(
              value: settings.viewMode,
              onChanged: (viewMode) =>
                  _update(settings.copyWith(viewMode: viewMode)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  strings.margins,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<double>(
                    emptySelectionAllowed: true,
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 5),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                    segments: [
                      ButtonSegment(value: 12.7, label: Text(strings.narrow)),
                      ButtonSegment(value: 20, label: Text(strings.normal)),
                      ButtonSegment(value: 25.4, label: Text(strings.wide)),
                    ],
                    selected: marginPreset == null ? {} : {marginPreset},
                    onSelectionChanged: (selection) {
                      if (selection.isNotEmpty) {
                        _uniform(settings, selection.single);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) => _MarginFields(
                projectId: project.id,
                settings: settings,
                fourColumns: constraints.maxWidth >= 330,
                strings: strings,
                onChanged: _update,
              ),
            ),
          ],
        ),
      ),
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

  double? _uniformMarginPreset(BookLayoutSettings settings) {
    for (final value in const [12.7, 20.0, 25.4]) {
      if (_allMarginsEqual(settings, value)) return value;
    }
    return null;
  }
}

class _ReadOnlySettingValue extends StatelessWidget {
  const _ReadOnlySettingValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Theme.of(context).inputDecorationTheme.fillColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(height: 1),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.1),
        ),
      ],
    ),
  );
}

class _MarginFields extends StatelessWidget {
  const _MarginFields({
    required this.projectId,
    required this.settings,
    required this.fourColumns,
    required this.strings,
    required this.onChanged,
  });

  final String projectId;
  final BookLayoutSettings settings;
  final bool fourColumns;
  final AppStrings strings;
  final ValueChanged<BookLayoutSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final fields = [
      BookSettingNumberField(
        key: ValueKey('$projectId-margin-top'),
        label: strings.top,
        value: settings.marginTopMm,
        minimum: 5,
        maximum: 50,
        suffix: strings.millimeters,
        onChanged: (value) => onChanged(settings.copyWith(marginTopMm: value)),
      ),
      BookSettingNumberField(
        key: ValueKey('$projectId-margin-bottom'),
        label: strings.bottom,
        value: settings.marginBottomMm,
        minimum: 5,
        maximum: 50,
        suffix: strings.millimeters,
        onChanged: (value) =>
            onChanged(settings.copyWith(marginBottomMm: value)),
      ),
      BookSettingNumberField(
        key: ValueKey('$projectId-margin-left'),
        label: strings.left,
        value: settings.marginLeftMm,
        minimum: 5,
        maximum: 50,
        suffix: strings.millimeters,
        onChanged: (value) => onChanged(settings.copyWith(marginLeftMm: value)),
      ),
      BookSettingNumberField(
        key: ValueKey('$projectId-margin-right'),
        label: strings.right,
        value: settings.marginRightMm,
        minimum: 5,
        maximum: 50,
        suffix: strings.millimeters,
        onChanged: (value) =>
            onChanged(settings.copyWith(marginRightMm: value)),
      ),
    ];
    if (fourColumns) {
      return Row(
        children: [
          for (var index = 0; index < fields.length; index++) ...[
            if (index > 0) const SizedBox(width: 6),
            Expanded(child: fields[index]),
          ],
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: fields[0]),
            const SizedBox(width: 8),
            Expanded(child: fields[1]),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: fields[2]),
            const SizedBox(width: 8),
            Expanded(child: fields[3]),
          ],
        ),
      ],
    );
  }
}
