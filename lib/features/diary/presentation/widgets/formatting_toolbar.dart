import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class DiaryFormattingToolbar extends StatelessWidget {
  const DiaryFormattingToolbar({required this.controller, super.key});

  final QuillController controller;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.surface,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: QuillSimpleToolbar(
        controller: controller,
        config: const QuillSimpleToolbarConfig(
          multiRowsDisplay: false,
          showFontFamily: false,
          showFontSize: false,
          showColorButton: false,
          showBackgroundColorButton: false,
          showClearFormat: false,
          showSearchButton: false,
        ),
      ),
    ),
  );
}

class FormattingSheet extends StatelessWidget {
  const FormattingSheet({required this.controller, super.key});

  final QuillController controller;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: QuillSimpleToolbar(
          controller: controller,
          config: const QuillSimpleToolbarConfig(multiRowsDisplay: false),
        ),
      ),
    ),
  );
}
