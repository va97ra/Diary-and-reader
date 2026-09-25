import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_compact_dropdown.dart';
import 'package:flutter/material.dart';

/// The text settings of the whole manuscript: every value is a compact
/// drop-down, and the three paragraph spacings share one line.
class BookParagraphSettingsSection extends StatelessWidget {
  const BookParagraphSettingsSection({required this.controller, super.key});

  final AuthorWorkspaceController controller;

  static const _lineHeights = <double>[1, 1.15, 1.35, 1.5, 2];
  static const _indentsMm = <double>[0, 5, 7.5, 10, 12.7, 15, 20];
  static const _spacingsPt = <double>[0, 3, 6, 8, 10, 12, 18, 24];

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = controller.activeProject!;
    final settings = project.paragraphSettings;
    String points(double value) =>
        '${bookSettingNumber(value)} ${strings.points}';
    String millimeters(double value) =>
        '${bookSettingNumber(value)} ${strings.millimeters}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          children: [
            BookCompactDropdown<BookParagraphPreset>(
              key: ValueKey('${project.id}-paragraph-preset'),
              label: strings.stylePreset,
              value: settings.preset,
              items: {
                for (final preset in BookParagraphPreset.values)
                  preset: _presetLabel(strings, preset),
              },
              onChanged: (preset) => controller.updateParagraphSettings(
                BookParagraphSettings.forPreset(preset),
              ),
            ),
            BookCompactDropdown<String>(
              key: ValueKey('${project.id}-default-font'),
              label: strings.defaultFont,
              value: settings.fontFamily,
              items: {for (final font in bookFontFamilies) font: font},
              itemStyle: (font) => TextStyle(fontFamily: font),
              onChanged: (font) => _update(settings.copyWith(fontFamily: font)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Row(
          children: [
            BookCompactDropdown<double>(
              key: ValueKey('${project.id}-default-font-size'),
              label: strings.fontSize,
              value: settings.fontSizePt,
              items: bookNumberChoices(
                bookFontSizesPt,
                settings.fontSizePt,
                points,
              ),
              onChanged: (value) =>
                  _update(settings.copyWith(fontSizePt: value)),
            ),
            BookCompactDropdown<double>(
              key: ValueKey('${project.id}-line-spacing'),
              label: strings.lineSpacing,
              value: settings.lineHeight,
              items: bookNumberChoices(
                _lineHeights,
                settings.lineHeight,
                bookSettingNumber,
              ),
              onChanged: (value) =>
                  _update(settings.copyWith(lineHeight: value)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _Row(
          children: [
            BookCompactDropdown<double>(
              key: ValueKey('${project.id}-paragraph-indent'),
              label: strings.paragraphIndent,
              value: settings.paragraphIndentMm,
              items: bookNumberChoices(
                _indentsMm,
                settings.paragraphIndentMm,
                millimeters,
              ),
              onChanged: (value) =>
                  _update(settings.copyWith(paragraphIndentMm: value)),
            ),
            BookCompactDropdown<double>(
              key: ValueKey('${project.id}-spacing-before'),
              label: strings.spacingBefore,
              value: settings.spacingBeforePt,
              items: bookNumberChoices(
                _spacingsPt,
                settings.spacingBeforePt,
                points,
              ),
              onChanged: (value) =>
                  _update(settings.copyWith(spacingBeforePt: value)),
            ),
            BookCompactDropdown<double>(
              key: ValueKey('${project.id}-spacing-after'),
              label: strings.spacingAfter,
              value: settings.spacingAfterPt,
              items: bookNumberChoices(
                _spacingsPt,
                settings.spacingAfterPt,
                points,
              ),
              onChanged: (value) =>
                  _update(settings.copyWith(spacingAfterPt: value)),
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
}

/// Settings side by side, equally wide.
class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (index, child) in children.indexed) ...[
        if (index > 0) const SizedBox(width: 8),
        Expanded(child: child),
      ],
    ],
  );
}
