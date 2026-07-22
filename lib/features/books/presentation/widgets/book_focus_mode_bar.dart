import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/workspace_save_state.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_save_status.dart';
import 'package:flutter/material.dart';

class BookFocusModeBar extends StatelessWidget {
  const BookFocusModeBar({
    required this.saveState,
    required this.onRetrySave,
    required this.onExit,
    super.key,
  });

  final WorkspaceSaveState saveState;
  final VoidCallback onRetrySave;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF141824),
    child: SafeArea(
      bottom: false,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Row(
            children: [
              BookSaveStatus(state: saveState, onRetry: onRetrySave),
              const Spacer(),
              IconButton(
                key: const ValueKey('editor-exit-focus-mode'),
                tooltip: AppStrings.of(context).exitFocusWriting,
                visualDensity: VisualDensity.compact,
                onPressed: onExit,
                icon: const Icon(Icons.fullscreen_exit),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
