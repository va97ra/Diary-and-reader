import 'package:flutter/material.dart';

// The building blocks of every settings sheet, so that the writer, the
// reader and the app settings look and behave alike.

/// A section of a settings sheet: a card with a title and, when the title
/// alone may puzzle a newcomer, a one-line hint.
class BookSettingsCard extends StatelessWidget {
  const BookSettingsCard({
    required this.title,
    required this.child,
    this.hint,
    this.icon,
    super.key,
  });

  final String title;
  final String? hint;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon case final icon?) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (hint case final hint?)
              Text(
                hint,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// Settings side by side, equally wide.
class BookSettingsRow extends StatelessWidget {
  const BookSettingsRow({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (index, child) in children.indexed) ...[
        if (index > 0) const SizedBox(width: 8),
        Expanded(child: child),
      ],
    ],
  );
}

/// A choice between two or three options that are all shown at once.
class BookCompactChoice<T> extends StatelessWidget {
  const BookCompactChoice({
    required this.value,
    required this.options,
    required this.onChanged,
    this.label,
    super.key,
  });

  final String? label;

  /// The selected option, or null when none of them matches.
  final T? value;
  final List<(T value, IconData? icon, String label)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final choice = SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        emptySelectionAllowed: true,
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        segments: [
          for (final (option, icon, text) in options)
            ButtonSegment(
              value: option,
              icon: icon == null ? null : Icon(icon, size: 17),
              label: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
        selected: {?value},
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) onChanged(selection.single);
        },
      ),
    );
    final label = this.label;
    if (label == null) return choice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        choice,
      ],
    );
  }
}

/// An on-off setting with a short name and, if needed, a hint below it.
class BookSettingSwitch extends StatelessWidget {
  const BookSettingSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
    this.hint,
    super.key,
  });

  final String title;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    dense: true,
    visualDensity: const VisualDensity(vertical: -3),
    title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
    subtitle: hint == null
        ? null
        : Text(
            hint!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
    value: value,
    onChanged: onChanged,
  );
}

/// A number changed a step at a time, such as the size of the text, so
/// that every tap shows its effect at once.
class BookSettingStepper extends StatelessWidget {
  const BookSettingStepper({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
    this.decreaseTooltip,
    this.increaseTooltip,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final String? decreaseTooltip;
  final String? increaseTooltip;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: decreaseTooltip,
          visualDensity: VisualDensity.compact,
          onPressed: onDecrease,
          icon: const Icon(Icons.remove, size: 18),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        IconButton(
          tooltip: increaseTooltip,
          visualDensity: VisualDensity.compact,
          onPressed: onIncrease,
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    ),
  );
}

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
      contentPadding: const EdgeInsets.fromLTRB(10, 9, 4, 9),
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

/// Named choices of a numeric setting, such as narrow or wide margins, plus
/// its current value under [fallback] when that is none of them.
Map<double, String> bookNamedChoices(
  Map<double, String> named,
  double current,
  String Function(double value) fallback,
) {
  final values = {...named.keys, current}.toList()..sort();
  return {for (final value in values) value: named[value] ?? fallback(value)};
}

/// Formats a setting without trailing zeros: 1, 1.15, 12.7.
String bookSettingNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
