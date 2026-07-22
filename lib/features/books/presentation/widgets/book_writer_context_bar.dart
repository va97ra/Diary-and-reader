import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BookWriterContextBar extends StatelessWidget {
  const BookWriterContextBar({
    required this.onStructure,
    required this.onUndo,
    required this.onRedo,
    required this.onFormatting,
    required this.onSettings,
    super.key,
  });

  final VoidCallback onStructure;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onFormatting;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Material(
      key: const ValueKey('writer-context-bar'),
      color: AppTheme.surface,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _Action(
                key: const ValueKey('writer-structure-action'),
                icon: Icons.account_tree_outlined,
                label: strings.structure,
                onTap: onStructure,
              ),
              _Action(
                key: const ValueKey('writer-undo-action'),
                icon: Icons.undo,
                label: strings.undo,
                onTap: onUndo,
              ),
              _Action(
                key: const ValueKey('writer-redo-action'),
                icon: Icons.redo,
                label: strings.redo,
                onTap: onRedo,
              ),
              _Action(
                key: const ValueKey('writer-formatting-action'),
                icon: Icons.text_format,
                label: strings.writerFormatting,
                onTap: onFormatting,
                accent: true,
              ),
              _Action(
                key: const ValueKey('writer-settings-action'),
                icon: Icons.tune,
                label: strings.settings,
                onTap: onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = !enabled
        ? const Color(0xFF64748B)
        : accent
        ? AppTheme.accent
        : const Color(0xFFE2E8F0);
    return Expanded(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 21, color: color),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10.5, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
