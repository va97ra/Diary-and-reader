import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_paragraph_settings_section.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_paragraph_style_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookFormattingToolbar extends StatelessWidget {
  const BookFormattingToolbar({
    required this.controller,
    required this.paragraphSettings,
    required this.onInsertImage,
    required this.onInsertPageBreak,
    super.key,
  });

  final QuillController controller;
  final BookParagraphSettings paragraphSettings;
  final VoidCallback onInsertImage;
  final VoidCallback onInsertPageBreak;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.surface,
    child: Row(
      children: [
        SizedBox(
          width: 210,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
            child: BookParagraphStyleSelector(controller: controller),
          ),
        ),
        const SizedBox(height: 34, child: VerticalDivider(width: 12)),
        IconButton(
          key: const ValueKey('insert-book-image-button'),
          tooltip: AppStrings.of(context).insertImage,
          onPressed: onInsertImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
        ),
        IconButton(
          key: const ValueKey('insert-book-page-break-button'),
          tooltip: AppStrings.of(context).insertPageBreak,
          onPressed: onInsertPageBreak,
          icon: const Icon(Icons.insert_page_break_outlined),
        ),
        const SizedBox(height: 34, child: VerticalDivider(width: 12)),
        Expanded(
          child: QuillSimpleToolbar(
            controller: controller,
            config: _bookToolbarConfig(paragraphSettings),
          ),
        ),
      ],
    ),
  );
}

class BookFormattingSheet extends StatelessWidget {
  const BookFormattingSheet({
    required this.workspaceController,
    required this.controller,
    required this.paragraphSettings,
    required this.onInsertImage,
    required this.onInsertPageBreak,
    super.key,
  });

  final AuthorWorkspaceController workspaceController;
  final QuillController controller;
  final BookParagraphSettings paragraphSettings;
  final VoidCallback onInsertImage;
  final VoidCallback onInsertPageBreak;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final options = _bookToolbarButtonOptions(paragraphSettings);
    const baseOptions = QuillToolbarBaseButtonOptions(
      iconSize: 18,
      iconButtonFactor: 1.65,
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookLeatherModalHeader(
              title: strings.writerFormatting,
              onClose: () => Navigator.maybePop(context),
              closeKey: const ValueKey('writer-formatting-close'),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
            ),
            const SizedBox(height: 4),
            BookParagraphStyleSelector(controller: controller),
            const SizedBox(height: 8),
            _FormattingSection(
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
                        strings.image,
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
            const SizedBox(height: 8),
            _FormattingSection(
              key: const ValueKey('formatting-text-section'),
              title: strings.characterFormatting,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _FormattingDropdown<String>(
                          key: const ValueKey('formatting-font-family'),
                          listenable: controller,
                          value: () =>
                              _currentFontFamily(controller, paragraphSettings),
                          values: {
                            for (final family in bookFontFamilies)
                              family: family,
                          },
                          onChanged: (family) => controller.formatSelection(
                            Attribute.fromKeyValue(Attribute.font.key, family),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 104,
                        child: _FormattingDropdown<double>(
                          key: const ValueKey('formatting-font-size'),
                          listenable: controller,
                          value: () =>
                              _currentFontSize(controller, paragraphSettings),
                          values: {
                            for (final points in _fontSizes)
                              points: '${_number(points)} pt',
                          },
                          onChanged: (points) => controller.formatSelection(
                            Attribute.fromKeyValue(
                              Attribute.size.key,
                              BookPageFormat.pointsToLogicalPixels(points),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _EvenToolbarRow(
                    children: [
                      QuillToolbarToggleStyleButton(
                        controller: controller,
                        attribute: Attribute.bold,
                        options: options.bold,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarToggleStyleButton(
                        controller: controller,
                        attribute: Attribute.italic,
                        options: options.italic,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarToggleStyleButton(
                        controller: controller,
                        attribute: Attribute.underline,
                        options: options.underLine,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarToggleStyleButton(
                        controller: controller,
                        attribute: Attribute.strikeThrough,
                        options: options.strikeThrough,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarToggleStyleButton(
                        controller: controller,
                        attribute: Attribute.subscript,
                        options: options.subscript,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarToggleStyleButton(
                        controller: controller,
                        attribute: Attribute.superscript,
                        options: options.superscript,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarToggleStyleButton(
                        controller: controller,
                        attribute: Attribute.inlineCode,
                        options: options.inlineCode,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarLinkStyleButton(
                        controller: controller,
                        options: options.linkStyle,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarClearFormatButton(
                        controller: controller,
                        options: options.clearFormat,
                        baseOptions: baseOptions,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _FormattingSection(
              key: const ValueKey('formatting-paragraph-section'),
              title: strings.paragraphFormatting,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _EvenToolbarRow(
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
                                baseOptions: baseOptions,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 82,
                        child: _FormattingDropdown<double>(
                          key: const ValueKey('formatting-line-height'),
                          listenable: controller,
                          value: () =>
                              _currentLineHeight(controller, paragraphSettings),
                          values: {
                            for (final height in _lineHeights)
                              height: _number(height),
                          },
                          onChanged: (height) => controller.formatSelection(
                            Attribute.fromKeyValue(
                              Attribute.lineHeight.key,
                              height,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _EvenToolbarRow(
                    children: [
                      QuillToolbarToggleStyleButton(
                        controller: controller,
                        attribute: Attribute.ol,
                        options: options.listNumbers,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarToggleStyleButton(
                        controller: controller,
                        attribute: Attribute.ul,
                        options: options.listBullets,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarToggleCheckListButton(
                        controller: controller,
                        options: options.toggleCheckList,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarToggleStyleButton(
                        controller: controller,
                        attribute: Attribute.blockQuote,
                        options: options.quote,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarToggleStyleButton(
                        controller: controller,
                        attribute: Attribute.codeBlock,
                        options: options.codeBlock,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarIndentButton(
                        controller: controller,
                        isIncrease: false,
                        options: options.indentDecrease,
                        baseOptions: baseOptions,
                      ),
                      QuillToolbarIndentButton(
                        controller: controller,
                        isIncrease: true,
                        options: options.indentIncrease,
                        baseOptions: baseOptions,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _FormattingSection(
              key: const ValueKey('formatting-manuscript-section'),
              title: strings.wholeManuscriptFormatting,
              child: BookParagraphSettingsSection(
                controller: workspaceController,
                showHeading: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

QuillSimpleToolbarConfig _bookToolbarConfig(BookParagraphSettings settings) =>
    QuillSimpleToolbarConfig(
      multiRowsDisplay: true,
      showColorButton: false,
      showBackgroundColorButton: false,
      showSearchButton: false,
      showLineHeightButton: true,
      showAlignmentButtons: true,
      showIndent: true,
      buttonOptions: _bookToolbarButtonOptions(settings),
    );

QuillSimpleToolbarButtonOptions _bookToolbarButtonOptions(
  BookParagraphSettings settings,
) => QuillSimpleToolbarButtonOptions(
  fontFamily: QuillToolbarFontFamilyButtonOptions(
    defaultDisplayText: settings.fontFamily,
    items: {for (final family in bookFontFamilies) family: family},
  ),
  fontSize: QuillToolbarFontSizeButtonOptions(
    defaultDisplayText: '${_number(settings.fontSizePt)} pt',
    items: {
      for (final points in _fontSizes)
        _number(points): _number(BookPageFormat.pointsToLogicalPixels(points)),
    },
  ),
  selectLineHeightStyleDropdownButton:
      QuillToolbarSelectLineHeightStyleDropdownButtonOptions(
        defaultDisplayText: _number(settings.lineHeight),
      ),
);

class _FormattingSection extends StatelessWidget {
  const _FormattingSection({
    required this.title,
    required this.child,
    super.key,
  });

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
          const SizedBox(height: 6),
          child,
        ],
      ),
    ),
  );
}

class _FormattingDropdown<T> extends StatelessWidget {
  const _FormattingDropdown({
    required this.listenable,
    required this.value,
    required this.values,
    required this.onChanged,
    super.key,
  });

  final Listenable listenable;
  final T Function() value;
  final Map<T, String> values;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: listenable,
    builder: (context, _) => Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value(),
          isExpanded: true,
          isDense: true,
          iconSize: 20,
          items: [
            for (final entry in values.entries)
              DropdownMenuItem<T>(
                value: entry.key,
                child: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
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

const _fontSizes = <double>[8, 9, 10, 11, 12, 14, 16, 18, 20, 24, 28, 32, 36];
const _lineHeights = <double>[1, 1.15, 1.5, 2];

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
  return _nearest(points, _fontSizes);
}

double _currentLineHeight(
  QuillController controller,
  BookParagraphSettings settings,
) {
  final raw = controller
      .getSelectionStyle()
      .attributes[Attribute.lineHeight.key]
      ?.value;
  final parsed = raw is num ? raw.toDouble() : double.tryParse('$raw');
  return _nearest(parsed ?? settings.lineHeight, _lineHeights);
}

double _nearest(double value, List<double> options) => options.reduce(
  (best, candidate) =>
      (candidate - value).abs() < (best - value).abs() ? candidate : best,
);

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
