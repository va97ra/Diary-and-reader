import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_style.dart';
import 'package:dnevnik/features/books/presentation/book_paragraph_style_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookParagraphStyleSelector extends StatelessWidget {
  const BookParagraphStyleSelector({required this.controller, super.key});

  final QuillController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final strings = AppStrings.of(context);
      final current = BookParagraphStyleActions.current(controller);
      return InputDecorator(
        decoration: InputDecoration(
          labelText: strings.paragraphType,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<BookParagraphStyle>(
            key: const ValueKey('paragraph-style-selector'),
            value: current,
            isDense: true,
            isExpanded: true,
            items: BookParagraphStyle.values
                .map(
                  (style) => DropdownMenuItem(
                    value: style,
                    child: Text(
                      _label(strings, style),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (style) {
              if (style != null) {
                BookParagraphStyleActions.apply(controller, style);
              }
            },
          ),
        ),
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
        BookParagraphStyle.sceneBreak => strings.sceneBreak,
      };
}
