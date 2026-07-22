import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/workspace_save_state.dart';
import 'package:flutter/material.dart';

class BookSaveStatus extends StatelessWidget {
  const BookSaveStatus({
    required this.state,
    required this.onRetry,
    this.compact = false,
    super.key,
  });

  final WorkspaceSaveState state;
  final bool compact;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final (label, icon, color) = switch (state) {
      WorkspaceSaveState.saved => (
        strings.saved,
        Icons.check_circle_outline,
        const Color(0xFFBBF7D0),
      ),
      WorkspaceSaveState.saving => (
        strings.saving,
        Icons.sync,
        const Color(0xFFE2E8F0),
      ),
      WorkspaceSaveState.error => (
        strings.saveError,
        Icons.error_outline,
        const Color(0xFFFCA5A5),
      ),
    };
    final status = AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: FittedBox(
        key: ValueKey(state),
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 10 : 11, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: compact ? 8.5 : 9.5,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      key: const ValueKey('writer-save-status'),
      liveRegion: true,
      button: state == WorkspaceSaveState.error,
      label: label,
      child: state == WorkspaceSaveState.error
          ? Tooltip(
              message: strings.saveError,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: onRetry,
                child: status,
              ),
            )
          : status,
    );
  }
}
