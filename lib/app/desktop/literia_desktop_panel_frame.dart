import 'dart:async';

import 'package:dnevnik/app/desktop/literia_desktop_shell.dart';
import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

/// Puts a slim bar above the app while it is a panel beside the clock: the
/// panel has no title bar, so the bar expands it or hides it in the tray.
class LiteriaDesktopPanelFrame extends StatelessWidget {
  const LiteriaDesktopPanelFrame({
    required this.shell,
    required this.child,
    super.key,
  });

  final LiteriaDesktopShell shell;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: shell.mode,
    builder: (context, mode, app) => Column(
      children: [
        // The bar comes and goes in place, so the app below keeps its state.
        if (mode == LiteriaWindowMode.panel)
          _PanelBar(shell: shell)
        else
          const SizedBox.shrink(),
        Expanded(child: app!),
      ],
    ),
    child: child,
  );
}

class _PanelBar extends StatelessWidget {
  const _PanelBar({required this.shell});

  final LiteriaDesktopShell shell;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('desktop-panel-bar'),
      color: colors.surfaceContainerHigh,
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            const SizedBox(width: 14),
            Icon(Icons.auto_stories_outlined, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                strings.studioTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            TextButton.icon(
              key: const ValueKey('desktop-panel-expand'),
              onPressed: () => unawaited(shell.showWindow()),
              icon: const Icon(Icons.open_in_full, size: 16),
              label: Text(strings.expandToWindow),
            ),
            TextButton.icon(
              key: const ValueKey('desktop-panel-hide'),
              onPressed: () => unawaited(shell.hide()),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              label: Text(strings.hideToTray),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
