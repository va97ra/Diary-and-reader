import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookSettingNumberField extends StatefulWidget {
  const BookSettingNumberField({
    required this.label,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
    this.suffix,
    super.key,
  });

  final String label;
  final double value;
  final double minimum;
  final double maximum;
  final String? suffix;
  final ValueChanged<double> onChanged;

  @override
  State<BookSettingNumberField> createState() => _BookSettingNumberFieldState();
}

class _BookSettingNumberFieldState extends State<BookSettingNumberField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant BookSettingNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) _commit();
  }

  void _commit() {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '.'));
    if (parsed == null) {
      _controller.text = _format(widget.value);
      return;
    }
    final value = parsed.clamp(widget.minimum, widget.maximum).toDouble();
    _controller.text = _format(value);
    if (value != widget.value) widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    focusNode: _focusNode,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
      LengthLimitingTextInputFormatter(5),
    ],
    decoration: InputDecoration(
      labelText: widget.label,
      suffixText: widget.suffix,
      border: const OutlineInputBorder(),
    ),
    onSubmitted: (_) => _commit(),
  );

  String _format(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }
}
