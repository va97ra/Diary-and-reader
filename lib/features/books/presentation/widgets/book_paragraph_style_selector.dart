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
                    child: Row(
                      children: [
                        Icon(_icon(style), size: 17),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _label(strings, style),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  IconData _icon(BookParagraphStyle style) => switch (style) {
    BookParagraphStyle.body => Icons.notes,
    BookParagraphStyle.heading1 => Icons.title,
    BookParagraphStyle.heading2 => Icons.text_fields,
    BookParagraphStyle.heading3 => Icons.short_text,
    BookParagraphStyle.quote => Icons.format_quote,
    BookParagraphStyle.epigraph => Icons.format_align_right,
    BookParagraphStyle.sceneBreak => Icons.more_horiz,
  };

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
