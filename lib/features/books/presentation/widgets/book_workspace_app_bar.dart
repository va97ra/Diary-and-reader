import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/workspace_save_state.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_editor_metrics.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_save_status.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum BookWorkspaceAction { search, export, preview, history, backup, restore }

class BookWorkspaceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const BookWorkspaceAppBar({
    required this.bookTitle,
    required this.sectionTitle,
    required this.metrics,
    required this.saveState,
    required this.onRenameBook,
    required this.onRenameSection,
    required this.onRetrySave,
    required this.onFocusMode,
    required this.onAction,
    super.key,
  });

  final String bookTitle;
  final String sectionTitle;
  final BookEditorMetrics metrics;
  final WorkspaceSaveState saveState;
  final VoidCallback onRenameBook;
  final VoidCallback onRenameSection;
  final VoidCallback onRetrySave;
  final VoidCallback onFocusMode;
  final ValueChanged<BookWorkspaceAction> onAction;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return AppBar(
      key: const ValueKey('writer-app-bar'),
      backgroundColor: AppTheme.surface,
      foregroundColor: const Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      titleSpacing: 12,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 320;
          final metricsText = compact
              ? '${number.format(metrics.words)} '
                    '${strings.words.toLowerCase()} · '
                    '${metrics.activePage}/${metrics.pageCount}'
              : '${strings.words}: ${number.format(metrics.words)} · '
                    '${strings.page} ${metrics.activePage}/${metrics.pageCount}';
          return Row(
            children: [
              Expanded(
                flex: compact ? 3 : 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderTitleAction(
                      key: const ValueKey('writer-book-title-action'),
                      label: strings.bookTitle,
                      title: bookTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF8FAFC),
                      ),
                      onTap: onRenameBook,
                    ),
                    _HeaderTitleAction(
                      key: const ValueKey('writer-section-title-action'),
                      label: strings.chapterTitle,
                      title: sectionTitle,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE2E8F0),
                      ),
                      onTap: onRenameSection,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: compact ? 2 : 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Semantics(
                      label:
                          '${strings.words}: '
                          '${number.format(metrics.words)}, '
                          '${strings.page} ${metrics.activePage}/'
                          '${metrics.pageCount}',
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          key: const ValueKey('writer-header-metrics'),
                          metricsText,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: compact ? 9.5 : 11,
                                color: const Color(0xFFE2E8F0),
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    BookSaveStatus(
                      state: saveState,
                      compact: compact,
                      onRetry: onRetrySave,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          key: const ValueKey('writer-hide-panels-button'),
          tooltip: strings.focusWriting,
          onPressed: onFocusMode,
          icon: const Icon(Icons.fullscreen),
        ),
        PopupMenuButton<BookWorkspaceAction>(
          key: const ValueKey('writer-more-menu'),
          tooltip: strings.more,
          onSelected: onAction,
          itemBuilder: (_) => [
            _item(
              BookWorkspaceAction.search,
              Icons.manage_search,
              strings.findAndReplace,
            ),
            _item(
              BookWorkspaceAction.export,
              Icons.ios_share_outlined,
              strings.exportBook,
            ),
            _item(
              BookWorkspaceAction.preview,
              Icons.chrome_reader_mode_outlined,
              strings.previewBook,
            ),
            _item(
              BookWorkspaceAction.history,
              Icons.history,
              strings.versionHistory,
            ),
            _item(
              BookWorkspaceAction.backup,
              Icons.download_outlined,
              strings.backupProject,
            ),
            _item(
              BookWorkspaceAction.restore,
              Icons.upload_file_outlined,
              strings.restoreProjectBackup,
            ),
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Center(child: Text(strings.more)),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _HeaderTitleAction extends StatelessWidget {
  const _HeaderTitleAction({
    required this.label,
    required this.title,
    required this.onTap,
    this.style,
    super.key,
  });

  final String label;
  final String title;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: '$label: $title',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: SizedBox(
            height: 24,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.edit_outlined,
                    size: 12,
                    color: style?.color ?? const Color(0xFFE2E8F0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

PopupMenuItem<BookWorkspaceAction> _item(
  BookWorkspaceAction value,
  IconData icon,
  String label,
) => PopupMenuItem(
  value: value,
  child: ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label),
  ),
);
