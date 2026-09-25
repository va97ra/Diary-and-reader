import 'package:flutter/material.dart';

/// A small outlined drop-down with its name in the border, so that several
/// settings fit on one line of the formatting sheet.
class BookCompactDropdown<T> extends StatelessWidget {
  const BookCompactDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.leading,
    this.itemStyle,
    super.key,
  });

  final String label;
  final T? value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  /// Drawn before each label, such as a colour swatch.
  final Widget Function(T value)? leading;

  /// Styles each item, such as a font shown in itself.
  final TextStyle? Function(T value)? itemStyle;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        // A value outside the list, such as a colour from another app, shows
        // no item, and picking any item replaces it.
        value: items.containsKey(value) ? value : null,
        isDense: true,
        isExpanded: true,
        iconSize: 20,
        items: [
          for (final entry in items.entries)
            DropdownMenuItem<T>(
              value: entry.key,
              child: Row(
                children: [
                  if (leading case final leading?) ...[
                    leading(entry.key),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      entry.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: itemStyle?.call(entry.key),
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    ),
  );
}

/// The choices of a numeric setting plus its current value when that is not
/// one of them, as a value typed in an older version.
Map<double, String> bookNumberChoices(
  List<double> choices,
  double current,
  String Function(double value) label,
) {
  final values = {...choices, current}.toList()..sort();
  return {for (final value in values) value: label(value)};
}

/// Formats a setting without trailing zeros: 1, 1.15, 12.7.
String bookSettingNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
