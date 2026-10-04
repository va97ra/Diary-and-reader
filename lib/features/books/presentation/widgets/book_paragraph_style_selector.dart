import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_style.dart';
import 'package:dnevnik/features/books/presentation/book_paragraph_style_actions.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_settings_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookParagraphStyleSelector extends StatelessWidget {
  const BookParagraphStyleSelector({
    required this.controller,
    required this.onApplied,
    super.key,
  });

  final QuillController controller;

  /// Called once a style is applied, so the sheet can show the text.
  final VoidCallback onApplied;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final strings = AppStrings.of(context);
      return BookCompactDropdown<BookParagraphStyle>(
        key: const ValueKey('paragraph-style-selector'),
        label: strings.paragraphType,
        value: BookParagraphStyleActions.current(controller),
        items: {
          for (final style in BookParagraphStyle.values)
            style: _label(strings, style),
        },
        onChanged: (style) {
          BookParagraphStyleActions.apply(controller, style);
          onApplied();
        },
      );
    },
  );

  String _label(AppStrings strings, BookParagraphStyle style) =>
      switch (style) {
        BookParagraphStyle.body => strings.bodyText,
        BookParagraphStyle.heading1 => strings.heading1,
        BookParagraphStyle.heading2 => strings.heading2,
        BookParagraphStyle.heading3 => strings.heading3,
        BookParagraphStyle.quote => strings.quoteStyle,
        BookParagraphStyle.epigraph => strings.epigraph,
        BookParagraphStyle.verse => strings.verse,
        BookParagraphStyle.sceneBreak => strings.sceneBreak,
      };
}
