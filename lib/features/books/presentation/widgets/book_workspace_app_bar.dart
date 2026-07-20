import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_editor_metrics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum BookWorkspaceAction { search, export, preview, history, backup, restore }

class BookWorkspaceAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const BookWorkspaceAppBar({
    required this.bookTitle,
    required this.sectionTitle,
    required this.metrics,
    required this.onFocusMode,
    required this.onAction,
    super.key,
  });

  final String bookTitle;
  final String sectionTitle;
  final BookEditorMetrics metrics;
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: compact ? 3 : 5,
                    child: Text(
                      bookTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: compact ? 2 : 3,
                    child: Semantics(
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
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                sectionTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
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
