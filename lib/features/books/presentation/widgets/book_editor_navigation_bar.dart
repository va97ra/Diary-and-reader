import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BookEditorNavigationBar extends StatelessWidget {
  const BookEditorNavigationBar({
    required this.onManuscript,
    required this.onFormatting,
    super.key,
  });

  final VoidCallback onManuscript;
  final VoidCallback onFormatting;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return BottomAppBar(
      key: const ValueKey('editor-bottom-navigation'),
      height: 58,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: _EditorNavigationAction(
              icon: Icons.account_tree_outlined,
              label: strings.manuscript,
              onTap: onManuscript,
            ),
          ),
          Expanded(
            child: _EditorNavigationAction(
              icon: Icons.edit_outlined,
              label: strings.editor,
              selected: true,
            ),
          ),
          Expanded(
            child: _EditorNavigationAction(
              icon: Icons.text_format,
              label: strings.formatting,
              onTap: onFormatting,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorNavigationAction extends StatelessWidget {
  const _EditorNavigationAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.accent : Colors.white70;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
