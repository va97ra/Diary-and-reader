import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:flutter/material.dart';

class BookMetadataEditorDialog extends StatefulWidget {
  const BookMetadataEditorDialog({required this.metadata, super.key});

  final BookMetadata metadata;

  @override
  State<BookMetadataEditorDialog> createState() =>
      _BookMetadataEditorDialogState();
}

class _BookMetadataEditorDialogState extends State<BookMetadataEditorDialog> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'title': TextEditingController(text: widget.metadata.title),
      'author': TextEditingController(text: widget.metadata.author),
      'series': TextEditingController(text: widget.metadata.series),
      'genre': TextEditingController(text: widget.metadata.genre),
      'isbn': TextEditingController(text: widget.metadata.isbn),
      'publisher': TextEditingController(text: widget.metadata.publisher),
      'description': TextEditingController(text: widget.metadata.description),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AlertDialog(
      title: Text(strings.editMetadata),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('title', strings.bookTitle, autofocus: true),
              _field('author', strings.author),
              _field('series', strings.series),
              _field('genre', strings.genre),
              _field('isbn', strings.isbn),
              _field('publisher', strings.publisher),
              _field('description', strings.description, maxLines: 4),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        FilledButton(
          key: const ValueKey('save-book-metadata'),
          onPressed: _save,
          child: Text(strings.save),
        ),
      ],
    );
  }

  Widget _field(
    String key,
    String label, {
    int maxLines = 1,
    bool autofocus = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      key: ValueKey('book-metadata-$key'),
      controller: _controllers[key],
      autofocus: autofocus,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  void _save() {
    final title = _controllers['title']!.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(
      context,
      widget.metadata.copyWith(
        title: title,
        author: _controllers['author']!.text.trim(),
        series: _controllers['series']!.text.trim(),
        genre: _controllers['genre']!.text.trim(),
        isbn: _controllers['isbn']!.text.trim(),
        publisher: _controllers['publisher']!.text.trim(),
        description: _controllers['description']!.text.trim(),
      ),
    );
  }
}
