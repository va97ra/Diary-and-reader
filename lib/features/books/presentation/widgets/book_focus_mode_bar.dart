import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

class BookFocusModeBar extends StatelessWidget {
  const BookFocusModeBar({required this.onExit, super.key});

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF141824),
    child: SafeArea(
      bottom: false,
      child: SizedBox(
        height: 44,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              key: const ValueKey('editor-exit-focus-mode'),
              tooltip: AppStrings.of(context).exitFocusWriting,
              visualDensity: VisualDensity.compact,
              onPressed: onExit,
              icon: const Icon(Icons.fullscreen_exit),
            ),
          ),
        ),
      ),
    ),
  );
}
