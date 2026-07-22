import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

class BookRenameTitleDialog extends StatefulWidget {
  const BookRenameTitleDialog({
    required this.initialTitle,
    required this.label,
    required this.fieldKey,
    required this.saveKey,
    required this.strings,
    super.key,
  });

  final String initialTitle;
  final String label;
  final Key fieldKey;
  final Key saveKey;
  final AppStrings strings;

  @override
  State<BookRenameTitleDialog> createState() => _BookRenameTitleDialogState();
}

class _BookRenameTitleDialogState extends State<BookRenameTitleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: widget.initialTitle.length,
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.label),
    content: TextField(
      key: widget.fieldKey,
      controller: _controller,
      autofocus: true,
      maxLength: 120,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: _submit,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(widget.strings.cancel),
      ),
      FilledButton(
        key: widget.saveKey,
        onPressed: () => _submit(_controller.text),
        child: Text(widget.strings.save),
      ),
    ],
  );

  void _submit(String value) {
    final title = value.trim();
    if (title.isNotEmpty) Navigator.pop(context, title);
  }
}
