import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_page_view_mode.dart';
import 'package:flutter/material.dart';

class BookPageViewModeSelector extends StatelessWidget {
  const BookPageViewModeSelector({
    required this.value,
    required this.onChanged,
    this.compact = false,
    super.key,
  });

  final BookPageViewMode value;
  final ValueChanged<BookPageViewMode> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (compact) {
      return PopupMenuButton<BookPageViewMode>(
        key: const ValueKey('page-view-mode-menu'),
        tooltip: strings.viewMode,
        initialValue: value,
        padding: EdgeInsets.zero,
        icon: Icon(_icon(value), size: 19),
        onSelected: onChanged,
        itemBuilder: (_) => BookPageViewMode.values
            .map(
              (mode) => PopupMenuItem(
                value: mode,
                child: Row(
                  children: [
                    Icon(_icon(mode), size: 19),
                    const SizedBox(width: 10),
                    Text(_label(strings, mode)),
                  ],
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.viewMode, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: BookPageViewMode.values
              .map(
                (mode) => ChoiceChip(
                  key: ValueKey('page-view-mode-${mode.name}'),
                  avatar: Icon(_icon(mode), size: 17),
                  label: Text(_label(strings, mode)),
                  selected: value == mode,
                  onSelected: (_) => onChanged(mode),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  IconData _icon(BookPageViewMode mode) => switch (mode) {
    BookPageViewMode.continuous => Icons.view_stream_outlined,
    BookPageViewMode.singlePage => Icons.crop_portrait_outlined,
    BookPageViewMode.spread => Icons.menu_book_outlined,
  };

  String _label(AppStrings strings, BookPageViewMode mode) => switch (mode) {
    BookPageViewMode.continuous => strings.continuousPages,
    BookPageViewMode.singlePage => strings.singlePage,
    BookPageViewMode.spread => strings.twoPageSpread,
  };
}
