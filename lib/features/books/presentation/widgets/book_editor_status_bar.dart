import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/workspace_save_state.dart';
import 'package:dnevnik/features/books/domain/book_page_view_mode.dart';
import 'package:dnevnik/features/books/domain/manuscript_statistics.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_page_view_mode_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookEditorStatusBar extends StatelessWidget {
  const BookEditorStatusBar({
    required this.statistics,
    required this.activePage,
    required this.pageCount,
    required this.targetWords,
    required this.saveState,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.showViewModeSelector,
    super.key,
  });

  final ManuscriptStatistics statistics;
  final int activePage;
  final int pageCount;
  final int targetWords;
  final WorkspaceSaveState saveState;
  final BookPageViewMode viewMode;
  final ValueChanged<BookPageViewMode> onViewModeChanged;
  final bool showViewModeSelector;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final number = NumberFormat.decimalPattern(locale);
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.white70,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Material(
      key: const ValueKey('book-editor-status-bar'),
      color: AppTheme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          return SizedBox(
            height: compact ? 40 : 44,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18),
              child: Row(
                children: [
                  Text(
                    '${strings.words}: ${number.format(statistics.words)}',
                    style: textStyle,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 18),
                    Text(
                      '${strings.characters}: '
                      '${number.format(statistics.characters)}',
                      style: textStyle,
                    ),
                    const SizedBox(width: 18),
                    Text(
                      '${strings.paragraphs}: '
                      '${number.format(statistics.paragraphs)}',
                      style: textStyle,
                    ),
                  ],
                  if (targetWords > 0) ...[
                    const SizedBox(width: 18),
                    Expanded(
                      child: _GoalProgress(
                        statistics: statistics,
                        targetWords: targetWords,
                        formatter: number,
                        compact: compact,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  if (showViewModeSelector) ...[
                    SizedBox.square(
                      dimension: 36,
                      child: BookPageViewModeSelector(
                        value: viewMode,
                        onChanged: onViewModeChanged,
                        compact: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const SizedBox(width: 14),
                  Text(
                    '${strings.page} $activePage/$pageCount',
                    style: textStyle,
                  ),
                  const SizedBox(width: 14),
                  _SaveIndicator(state: saveState, compact: compact),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GoalProgress extends StatelessWidget {
  const _GoalProgress({
    required this.statistics,
    required this.targetWords,
    required this.formatter,
    required this.compact,
  });

  final ManuscriptStatistics statistics;
  final int targetWords;
  final NumberFormat formatter;
  final bool compact;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: compact ? 90 : 220),
    child: Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            minHeight: 5,
            value: statistics.progressFor(targetWords),
            borderRadius: BorderRadius.circular(999),
            backgroundColor: Colors.white12,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 8),
          Text(
            '${formatter.format(statistics.words)}/'
            '${formatter.format(targetWords)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    ),
  );
}

class _SaveIndicator extends StatelessWidget {
  const _SaveIndicator({required this.state, required this.compact});

  final WorkspaceSaveState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final (icon, label, color) = switch (state) {
      WorkspaceSaveState.saved => (
        Icons.cloud_done_outlined,
        strings.saved,
        Colors.white70,
      ),
      WorkspaceSaveState.saving => (
        Icons.cloud_sync_outlined,
        strings.saving,
        AppTheme.accent,
      ),
      WorkspaceSaveState.error => (
        Icons.cloud_off_outlined,
        strings.saveError,
        Colors.redAccent,
      ),
    };
    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          if (!compact) ...[
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ],
      ),
    );
  }
}
