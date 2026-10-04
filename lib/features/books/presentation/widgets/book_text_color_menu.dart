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

class BookTextColorSwatch extends StatelessWidget {
  const BookTextColorSwatch({required this.hex, this.size = 16, super.key});

  /// A `#rrggbb` colour, or empty for text without a colour of its own.
  final String hex;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: bookTextColorOf(hex),
      border: Border.all(color: Theme.of(context).colorScheme.onSurface),
    ),
  );
}

/// The sign of a colour button: a letter with a bar below it in the colour
/// of the words, or in a rainbow while they have none, so that the button
/// reads as the colour at a glance. The letter takes the icon colour.
class BookTextColorIcon extends StatelessWidget {
  const BookTextColorIcon({required this.hex, super.key});

  /// A `#rrggbb` colour, or empty for text without a colour of its own.
  final String hex;

  static const _rainbow = ['red', 'orange', 'green', 'blue', 'purple'];

  @override
  Widget build(BuildContext context) {
    final color = bookTextColorOf(hex);
    return SizedBox.square(
      dimension: 22,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'A',
            style: TextStyle(
              color: IconTheme.of(context).color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 18,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              gradient: color != null
                  ? null
                  : LinearGradient(
                      colors: [
                        for (final (id, color) in BookTextColors.palette)
                          if (_rainbow.contains(id)) color,
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
