import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/presentation/book_text_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// The colour of the words at the cursor as `#rrggbb`, or empty for text
/// without a colour of its own.
String bookTextColorAt(QuillController controller) =>
    controller
        .getSelectionStyle()
        .attributes[Attribute.color.key]
        ?.value
        ?.toString()
        .toLowerCase() ??
    '';

/// Colours the selected words; an empty [hex] takes their colour away.
void applyBookTextColor(QuillController controller, String hex) =>
    controller.formatSelection(ColorAttribute(hex.isEmpty ? null : hex));

/// [hex] as a colour, or null for text without a colour of its own.
Color? bookTextColorOf(String hex) => hex.isEmpty
    ? null
    : Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

/// The choices of a text colour menu, each with its swatch and name.
List<PopupMenuEntry<String>> bookTextColorMenuItems(BuildContext context) {
  final strings = AppStrings.of(context);
  return [
    for (final (hex, name) in [
      ('', strings.noTextColor),
      for (final (id, color) in BookTextColors.palette)
        (BookTextColors.hex(color), strings.textColorName(id)),
    ])
      PopupMenuItem(
        value: hex,
        child: Row(
          children: [
            BookTextColorSwatch(hex: hex),
            const SizedBox(width: 10),
            Text(name),
          ],
        ),
      ),
  ];
}

class BookTextColorSwatch extends StatelessWidget {
  const BookTextColorSwatch({required this.hex, super.key});

  /// A `#rrggbb` colour, or empty for text without a colour of its own.
  final String hex;

  @override
  Widget build(BuildContext context) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: bookTextColorOf(hex),
      border: Border.all(color: Theme.of(context).colorScheme.onSurface),
    ),
  );
}
