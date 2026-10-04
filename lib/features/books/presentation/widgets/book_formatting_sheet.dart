import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_paragraph_settings_section.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_paragraph_style_selector.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_settings_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// The formatting sheet of the writer. It goes from the small to the large:
/// the selected words, the paragraph under the cursor, things to insert, and
/// last the look of the whole book.
///
/// The sheet covers the text, so every change calls [onApplied], which hides
/// the sheet and shows what the change did.
class BookFormattingSheet extends StatelessWidget {
  const BookFormattingSheet({
    required this.workspaceController,
    required this.controller,
    required this.onInsertImage,
    required this.onInsertPageBreak,
    required this.onApplied,
    super.key,
  });

  final AuthorWorkspaceController workspaceController;
  final QuillController controller;
  final VoidCallback onInsertImage;
  final VoidCallback onInsertPageBreak;
  final VoidCallback onApplied;

  QuillToolbarBaseButtonOptions get _buttons => QuillToolbarBaseButtonOptions(
    iconSize: 18,
    iconButtonFactor: 1.65,
    afterButtonPressed: onApplied,
  );

  /// Applies a change to the text and hides the sheet.
  ValueChanged<T> _applying<T>(ValueChanged<T> change) => (value) {
    change(value);
    onApplied();
  };

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    // Words without their own font or size show the book's.
    final paragraphSettings =
        workspaceController.activeProject!.paragraphSettings;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookLeatherModalHeader(
              title: strings.writerFormatting,
              subtitle: strings.formattingHint,
              onClose: () => Navigator.maybePop(context),
              closeKey: const ValueKey('writer-formatting-close'),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
            ),
            // Bold, italic, colour and the like sit in the bar below the
            // selected words, where they need no sheet; the rare font and
            // size of some words stay here.
            BookSettingsCard(
              key: const ValueKey('formatting-text-section'),
              title: strings.characterFormatting,
              hint: strings.selectionBarHint,
              child: Row(
                children: [
                  Expanded(
                    child: _FormattingDropdown<String>(
                      key: const ValueKey('formatting-font-family'),
                      listenable: controller,
                      label: strings.font,
                      value: () =>
                          _currentFontFamily(controller, paragraphSettings),
                      values: {
                        for (final family in bookFontFamilies) family: family,
                      },
                      itemStyle: (family) => TextStyle(fontFamily: family),
                      onChanged: _applying(
                        (family) => controller.formatSelection(
                          Attribute.fromKeyValue(Attribute.font.key, family),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 104,
                    child: _FormattingDropdown<double>(
                      key: const ValueKey('formatting-font-size'),
                      listenable: controller,
                      label: strings.fontSize,
                      value: () =>
                          _currentFontSize(controller, paragraphSettings),
                      values: {
                        for (final points in bookFontSizesPt)
                          points:
                              '${bookSettingNumber(points)} '
                              '${strings.points}',
                      },
                      onChanged: _applying(
                        (points) => controller.formatSelection(
                          Attribute.fromKeyValue(
                            Attribute.size.key,
                            BookPageFormat.pointsToLogicalPixels(points),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            BookSettingsCard(
              key: const ValueKey('formatting-paragraph-section'),
              title: strings.paragraphFormatting,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BookParagraphStyleSelector(
                    controller: controller,
                    onApplied: onApplied,
                  ),
                  const SizedBox(height: 6),
                  // The spacing between lines is the book's, set below, so
                  // that every paragraph keeps the book's spacing around it.
                  _EvenToolbarRow(
                    children: [
                      for (final attribute in const [
                        Attribute.leftAlignment,
                        Attribute.centerAlignment,
                        Attribute.rightAlignment,
                        Attribute.justifyAlignment,
                      ])
                        QuillToolbarToggleStyleButton(
                          controller: controller,
                          attribute: attribute,
                          // Quill calls it justifying to the window width.
                          options: QuillToolbarToggleStyleButtonOptions(
                            tooltip: attribute == Attribute.justifyAlignment
                                ? strings.alignJustify
                                : null,
                          ),
                          baseOptions: _buttons,
                        ),
                      for (final increase in const [false, true])
                        QuillToolbarIndentButton(
                          controller: controller,
                          isIncrease: increase,
                          baseOptions: _buttons,
                        ),
                      for (final attribute in const [
                        Attribute.ol,
                        Attribute.ul,
                      ])
                        QuillToolbarToggleStyleButton(
                          controller: controller,
                          attribute: attribute,
                          baseOptions: _buttons,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            BookSettingsCard(
              key: const ValueKey('formatting-insert-section'),
              title: strings.insertIntoText,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('insert-book-image-button'),
                      onPressed: onInsertImage,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(
                        strings.picture,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('insert-book-page-break-button'),
                      onPressed: onInsertPageBreak,
                      icon: const Icon(Icons.insert_page_break_outlined),
                      label: Text(
                        strings.pageBreak,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            BookSettingsCard(
              key: const ValueKey('formatting-manuscript-section'),
              title: strings.wholeManuscriptFormatting,
              hint: strings.wholeBookHint,
              child: BookParagraphSettingsSection(
                controller: workspaceController,
                onApplied: onApplied,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A drop-down that follows the formatting at the cursor.
class _FormattingDropdown<T> extends StatelessWidget {
  const _FormattingDropdown({
    required this.listenable,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.itemStyle,
    super.key,
  });

  final Listenable listenable;
  final String label;
  final T Function() value;
  final Map<T, String> values;
  final ValueChanged<T> onChanged;
  final TextStyle? Function(T value)? itemStyle;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: listenable,
    builder: (context, _) => BookCompactDropdown<T>(
      label: label,
      value: value(),
      items: values,
      itemStyle: itemStyle,
      onChanged: onChanged,
    ),
  );
}

class _EvenToolbarRow extends StatelessWidget {
  const _EvenToolbarRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 38,
    child: Row(
      children: [
        for (final child in children) Expanded(child: Center(child: child)),
      ],
    ),
  );
}

String _currentFontFamily(
  QuillController controller,
  BookParagraphSettings settings,
) {
  final value = controller
      .getSelectionStyle()
      .attributes[Attribute.font.key]
      ?.value
      .toString();
  return value != null && bookFontFamilies.contains(value)
      ? value
      : settings.fontFamily;
}

double _currentFontSize(
  QuillController controller,
  BookParagraphSettings settings,
) {
  final raw = controller
      .getSelectionStyle()
      .attributes[Attribute.size.key]
      ?.value;
  final logicalPixels = raw is num
      ? raw.toDouble()
      : double.tryParse(raw?.toString() ?? '');
  if (logicalPixels == null) return settings.fontSizePt;
  final points =
      logicalPixels *
      BookPageFormat.pointsPerInch /
      BookPageFormat.logicalPixelsPerInch;
  return _nearest(points, bookFontSizesPt);
}

double _nearest(double value, List<double> options) => options.reduce(
  (best, candidate) =>
      (candidate - value).abs() < (best - value).abs() ? candidate : best,
);
