import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:flutter/material.dart';

class BookReaderNoteDialog extends StatefulWidget {
  const BookReaderNoteDialog({this.initialText = '', super.key});

  final String initialText;

  @override
  State<BookReaderNoteDialog> createState() => _BookReaderNoteDialogState();
}

class _BookReaderNoteDialogState extends State<BookReaderNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isEditing = widget.initialText.isNotEmpty;
    return BookLeatherDialog(
      title: Text(isEditing ? strings.editNote : strings.newNote),
      content: TextField(
        key: const ValueKey('reader-note-field'),
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 8,
        decoration: InputDecoration(
          hintText: strings.noteText,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          key: const ValueKey('reader-save-note'),
          onPressed: () {
            final value = _controller.text.trim();
            if (value.isNotEmpty) Navigator.of(context).pop(value);
          },
          child: Text(strings.save),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
