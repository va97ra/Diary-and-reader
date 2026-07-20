import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_setting_number_field.dart';
import 'package:flutter/material.dart';

class BookParagraphSettingsSection extends StatelessWidget {
  const BookParagraphSettingsSection({required this.controller, super.key});

  final AuthorWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = controller.activeProject!;
    final settings = project.paragraphSettings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.paragraphStyle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<BookParagraphPreset>(
          key: ValueKey(
            '${project.id}-paragraph-preset-${settings.preset.name}',
          ),
          initialValue: settings.preset,
          decoration: InputDecoration(
            labelText: strings.stylePreset,
            border: const OutlineInputBorder(),
          ),
          items: BookParagraphPreset.values
              .map(
                (preset) => DropdownMenuItem(
                  value: preset,
                  child: SizedBox(
                    width: 210,
                    child: Text(
                      _presetLabel(strings, preset),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (context) => BookParagraphPreset.values
              .map(
                (preset) => Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 210,
                    child: Text(
                      _presetLabel(strings, preset),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (preset) {
            if (preset != null) {
              controller.updateParagraphSettings(
                BookParagraphSettings.forPreset(preset),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('${project.id}-default-font-${settings.fontFamily}'),
          initialValue: settings.fontFamily,
          decoration: InputDecoration(
            labelText: strings.defaultFont,
            border: const OutlineInputBorder(),
          ),
          items: bookFontFamilies
              .map(
                (font) => DropdownMenuItem(
                  value: font,
                  child: Text(font, style: TextStyle(fontFamily: font)),
                ),
              )
              .toList(),
          onChanged: (font) {
            if (font != null) _update(settings.copyWith(fontFamily: font));
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BookSettingNumberField(
                key: ValueKey('${project.id}-default-font-size'),
                label: strings.fontSize,
                value: settings.fontSizePt,
                minimum: 8,
                maximum: 36,
                suffix: strings.points,
                onChanged: (value) =>
                    _update(settings.copyWith(fontSizePt: value)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BookSettingNumberField(
                key: ValueKey('${project.id}-paragraph-indent'),
                label: strings.paragraphIndent,
                value: settings.paragraphIndentMm,
                minimum: 0,
                maximum: 30,
                suffix: strings.millimeters,
                onChanged: (value) =>
                    _update(settings.copyWith(paragraphIndentMm: value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          strings.lineSpacing,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          children: [1.0, 1.15, 1.35, 1.5, 2.0]
              .map(
                (height) => ChoiceChip(
                  label: Text(_number(height)),
                  selected: (settings.lineHeight - height).abs() < 0.01,
                  onSelected: (_) =>
                      _update(settings.copyWith(lineHeight: height)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BookSettingNumberField(
                key: ValueKey('${project.id}-spacing-before'),
                label: strings.spacingBefore,
                value: settings.spacingBeforePt,
                minimum: 0,
                maximum: 72,
                suffix: strings.points,
                onChanged: (value) =>
                    _update(settings.copyWith(spacingBeforePt: value)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BookSettingNumberField(
                key: ValueKey('${project.id}-spacing-after'),
                label: strings.spacingAfter,
                value: settings.spacingAfterPt,
                minimum: 0,
                maximum: 72,
                suffix: strings.points,
                onChanged: (value) =>
                    _update(settings.copyWith(spacingAfterPt: value)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _update(BookParagraphSettings settings) =>
      controller.updateParagraphSettings(settings);

  String _presetLabel(AppStrings strings, BookParagraphPreset preset) =>
      switch (preset) {
        BookParagraphPreset.modern => strings.modernStyle,
        BookParagraphPreset.classic => strings.classicStyle,
        BookParagraphPreset.manuscript => strings.manuscriptStyle,
        BookParagraphPreset.custom => strings.customStyle,
      };

  String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}
