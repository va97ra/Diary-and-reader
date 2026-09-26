import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_page_view_mode.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_settings_controls.dart';
import 'package:flutter/material.dart';

/// How the pages of the manuscript look: the A4 preview, how the sheets are
/// shown, their orientation and margins.
class BookPageSettingsSection extends StatelessWidget {
  const BookPageSettingsSection({
    required this.controller,
    required this.a4Preview,
    required this.pagedLayout,
    required this.onToggleA4Preview,
    super.key,
  });

  final AuthorWorkspaceController controller;
  final bool a4Preview;
  final bool pagedLayout;
  final VoidCallback onToggleA4Preview;

  static const _marginPresetsMm = [12.7, 20.0, 25.4];
  static const _marginsMm = <double>[5, 10, 12.7, 15, 20, 25, 25.4, 30, 40, 50];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => _buildSettings(context),
  );

  Widget _buildSettings(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = controller.activeProject!;
    final settings = project.layoutSettings;
    BookCompactDropdown<double> margin(
      String key,
      String label,
      double value,
      BookLayoutSettings Function(double value) change,
    ) => BookCompactDropdown<double>(
      key: ValueKey('${project.id}-margin-$key'),
      label: label,
      value: value,
      items: bookNumberChoices(_marginsMm, value, bookSettingNumber),
      onChanged: (next) => _update(change(next)),
    );
    return BookSettingsCard(
      key: const ValueKey('writer-page-layout-section'),
      title: strings.pageLayout,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.tonalIcon(
            key: const ValueKey('writer-a4-preview-action'),
            onPressed: onToggleA4Preview,
            icon: Icon(
              a4Preview ? Icons.edit_note_outlined : Icons.description_outlined,
            ),
            label: Text(
              a4Preview ? strings.comfortableWriting : strings.a4Preview,
            ),
          ),
          // How sheets are shown only matters while there are sheets.
          if (pagedLayout) ...[
            const SizedBox(height: 12),
            BookCompactChoice<BookPageViewMode>(
              key: ValueKey('${project.id}-page-view-mode'),
              label: strings.viewMode,
              value: settings.viewMode,
              options: [
                (
                  BookPageViewMode.continuous,
                  Icons.view_stream_outlined,
                  strings.continuousPagesShort,
                ),
                (
                  BookPageViewMode.singlePage,
                  Icons.crop_portrait_outlined,
                  strings.singlePageShort,
                ),
                (
                  BookPageViewMode.spread,
                  Icons.menu_book_outlined,
                  strings.twoPageSpread,
                ),
              ],
              onChanged: (mode) => _update(settings.copyWith(viewMode: mode)),
            ),
          ],
          const SizedBox(height: 12),
          BookCompactChoice<BookPageOrientation>(
            key: ValueKey('${project.id}-page-orientation'),
            label: strings.orientation,
            value: settings.orientation,
            options: [
              (
                BookPageOrientation.portrait,
                Icons.crop_portrait,
                strings.portrait,
              ),
              (
                BookPageOrientation.landscape,
                Icons.crop_landscape,
                strings.landscape,
              ),
            ],
            onChanged: (orientation) =>
                _update(settings.copyWith(orientation: orientation)),
          ),
          const SizedBox(height: 12),
          BookCompactChoice<double>(
            key: ValueKey('${project.id}-margin-preset'),
            // The four fields below show bare numbers to fit on one line.
            label: '${strings.margins}, ${strings.millimeters}',
            value: _uniformMarginPreset(settings),
            options: [
              (_marginPresetsMm[0], null, strings.narrow),
              (_marginPresetsMm[1], null, strings.normal),
              (_marginPresetsMm[2], null, strings.wide),
            ],
            onChanged: (value) => _update(settings.withUniformMargins(value)),
          ),
          const SizedBox(height: 14),
          BookSettingsRow(
            children: [
              margin(
                'top',
                strings.top,
                settings.marginTopMm,
                (value) => settings.copyWith(marginTopMm: value),
              ),
              margin(
                'bottom',
                strings.bottom,
                settings.marginBottomMm,
                (value) => settings.copyWith(marginBottomMm: value),
              ),
              margin(
                'left',
                strings.left,
                settings.marginLeftMm,
                (value) => settings.copyWith(marginLeftMm: value),
              ),
              margin(
                'right',
                strings.right,
                settings.marginRightMm,
                (value) => settings.copyWith(marginRightMm: value),
              ),
            ],
          ),
          const SizedBox(height: 6),
          BookSettingSwitch(
            key: ValueKey('${project.id}-show-chapter-titles'),
            title: strings.showChapterTitlesInBody,
            hint: strings.showChapterTitlesInBodyHint,
            value: settings.showChapterTitlesInBody,
            onChanged: (value) =>
                _update(settings.copyWith(showChapterTitlesInBody: value)),
          ),
        ],
      ),
    );
  }

  void _update(BookLayoutSettings settings) =>
      controller.updateLayoutSettings(settings);

  double? _uniformMarginPreset(BookLayoutSettings settings) {
    bool allEqual(double value) => [
      settings.marginTopMm,
      settings.marginRightMm,
      settings.marginBottomMm,
      settings.marginLeftMm,
    ].every((margin) => (margin - value).abs() < 0.01);
    return _marginPresetsMm.where(allEqual).firstOrNull;
  }
}
