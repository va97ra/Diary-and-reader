import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/diary/domain/page_margins.dart';
import 'package:flutter/material.dart';

class MarginsSheet extends StatefulWidget {
  const MarginsSheet({
    required this.initialValue,
    required this.onApply,
    super.key,
  });

  final PageMargins initialValue;
  final ValueChanged<PageMargins> onApply;

  @override
  State<MarginsSheet> createState() => _MarginsSheetState();
}

class _MarginsSheetState extends State<MarginsSheet> {
  late PageMargins _value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.margins,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: Text(strings.normal),
                  onPressed: () =>
                      setState(() => _value = const PageMargins.normal()),
                ),
                ActionChip(
                  label: Text(strings.narrow),
                  onPressed: () =>
                      setState(() => _value = const PageMargins.narrow()),
                ),
                ActionChip(
                  label: Text(strings.wide),
                  onPressed: () =>
                      setState(() => _value = const PageMargins.wide()),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MarginField(
                    label: strings.top,
                    unit: strings.millimeters,
                    value: _value.top,
                    onChanged: (value) => _set(top: value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MarginField(
                    label: strings.bottom,
                    unit: strings.millimeters,
                    value: _value.bottom,
                    onChanged: (value) => _set(bottom: value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MarginField(
                    label: strings.left,
                    unit: strings.millimeters,
                    value: _value.left,
                    onChanged: (value) => _set(left: value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MarginField(
                    label: strings.right,
                    unit: strings.millimeters,
                    value: _value.right,
                    onChanged: (value) => _set(right: value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                widget.onApply(_value);
                Navigator.pop(context);
              },
              child: Text(strings.apply),
            ),
          ],
        ),
      ),
    );
  }

  void _set({double? top, double? right, double? bottom, double? left}) {
    setState(
      () => _value = PageMargins(
        top: top ?? _value.top,
        right: right ?? _value.right,
        bottom: bottom ?? _value.bottom,
        left: left ?? _value.left,
      ),
    );
  }
}

class _MarginField extends StatelessWidget {
  const _MarginField({
    required this.label,
    required this.unit,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String unit;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: value.toStringAsFixed(0),
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: '$label, $unit',
      border: const OutlineInputBorder(),
      filled: true,
    ),
    onChanged: (value) => onChanged(PageMargins.clamp(value)),
  );
}
