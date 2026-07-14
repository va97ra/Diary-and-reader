import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookFormattingToolbar extends StatelessWidget {
  const BookFormattingToolbar({required this.controller, super.key});

  final QuillController controller;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.surface,
    child: QuillSimpleToolbar(
      controller: controller,
      config: const QuillSimpleToolbarConfig(
        multiRowsDisplay: false,
        showColorButton: false,
        showBackgroundColorButton: false,
        showSearchButton: false,
      ),
    ),
  );
}

class BookFormattingSheet extends StatelessWidget {
  const BookFormattingSheet({required this.controller, super.key});

  final QuillController controller;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: QuillSimpleToolbar(
        controller: controller,
        config: const QuillSimpleToolbarConfig(multiRowsDisplay: false),
      ),
    ),
  );
}
