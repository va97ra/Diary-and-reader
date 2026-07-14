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
      config: _bookToolbarConfig,
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
        config: _bookToolbarConfig,
      ),
    ),
  );
}

const _bookToolbarConfig = QuillSimpleToolbarConfig(
  multiRowsDisplay: false,
  showColorButton: false,
  showBackgroundColorButton: false,
  showSearchButton: false,
  showLineHeightButton: true,
  showAlignmentButtons: true,
  showIndent: true,
  buttonOptions: QuillSimpleToolbarButtonOptions(
    fontFamily: QuillToolbarFontFamilyButtonOptions(
      defaultDisplayText: 'Georgia',
      items: {
        'Georgia': 'Georgia',
        'Times New Roman': 'Times New Roman',
        'Arial': 'Arial',
        'Calibri': 'Calibri',
        'Verdana': 'Verdana',
        'Tahoma': 'Tahoma',
        'Courier New': 'Courier New',
      },
    ),
    fontSize: QuillToolbarFontSizeButtonOptions(
      defaultDisplayText: '12 pt',
      items: {
        '8': '10.6667',
        '9': '12',
        '10': '13.3333',
        '11': '14.6667',
        '12': '16',
        '14': '18.6667',
        '16': '21.3333',
        '18': '24',
        '20': '26.6667',
        '24': '32',
        '28': '37.3333',
        '32': '42.6667',
        '36': '48',
      },
    ),
    selectLineHeightStyleDropdownButton:
        QuillToolbarSelectLineHeightStyleDropdownButtonOptions(
          defaultDisplayText: '1.5',
        ),
  ),
);
