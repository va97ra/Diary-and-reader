import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_library_query.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_adaptive_control_shell.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_cover_view.dart';
import 'package:flutter/material.dart';

class LiteriaHomePage extends StatelessWidget {
  const LiteriaHomePage({
    required this.lastManuscript,
    required this.lastReading,
    required this.onWrite,
    required this.onRead,
    required this.onSettings,
    required this.onContinueWriting,
    required this.onContinueReading,
    super.key,
  });

  final BookProject? lastManuscript;
  final BookProject? lastReading;
  final VoidCallback onWrite;
  final VoidCallback onRead;
  final VoidCallback onSettings;
  final VoidCallback onContinueWriting;
  final VoidCallback onContinueReading;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF160B07),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/home/desk-background.webp',
            fit: BoxFit.cover,
            semanticLabel: '',
          ),
          const ColoredBox(color: Color(0x66160B07)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HomeHeader(strings: strings),
                        const SizedBox(height: 14),
                        _PrimaryTiles(
                          availableWidth: constraints.maxWidth - 24,
                          textScale: MediaQuery.textScalerOf(context).scale(1),
                          onWrite: onWrite,
                          onRead: onRead,
                        ),
                        const SizedBox(height: 10),
                        _LiteriaActionTile(
                          key: const ValueKey('home-settings-tile'),
                          title: strings.settings,
                          subtitle: strings.settingsSubtitle,
                          asset: 'assets/home/organizer.webp',
                          onTap: onSettings,
                          horizontal: true,
                        ),
                        const SizedBox(height: 14),
                        _ContinueGrid(
                          lastManuscript: lastManuscript,
                          lastReading: lastReading,
                          onWrite: lastManuscript == null
                              ? onWrite
                              : onContinueWriting,
                          onRead: lastReading == null
                              ? onRead
                              : onContinueReading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        strings.studioTitle,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          color: const Color(0xFFFFF5DB),
          fontFamily: 'PT Serif',
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
        ),
      ),
      const SizedBox(height: 2),
      Text(
        strings.homeTagline,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: BookLeatherColors.mutedForeground,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
        ),
      ),
    ],
  );
}

class _PrimaryTiles extends StatelessWidget {
  const _PrimaryTiles({
    required this.availableWidth,
    required this.textScale,
    required this.onWrite,
    required this.onRead,
  });

  final double availableWidth;
  final double textScale;
  final VoidCallback onWrite;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final stacked = availableWidth < 350 || textScale > 1.3;
    final tiles = [
      _LiteriaActionTile(
        key: const ValueKey('home-write-tile'),
        title: strings.write,
        subtitle: strings.writeSubtitle,
        asset: 'assets/home/notebook.webp',
        onTap: onWrite,
      ),
      _LiteriaActionTile(
        key: const ValueKey('home-read-tile'),
        title: strings.read,
        subtitle: strings.readSubtitle,
        asset: 'assets/home/open-book.webp',
        onTap: onRead,
      ),
    ];
    if (stacked) {
      return Column(
        children: [tiles.first, const SizedBox(height: 10), tiles.last],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: tiles.first),
        const SizedBox(width: 10),
        Expanded(child: tiles.last),
      ],
    );
  }
}

class _LiteriaActionTile extends StatefulWidget {
  const _LiteriaActionTile({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.onTap,
    this.horizontal = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final String asset;
  final VoidCallback onTap;
  final bool horizontal;

  @override
  State<_LiteriaActionTile> createState() => _LiteriaActionTileState();
}

class _LiteriaActionTileState extends State<_LiteriaActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: _pressed ? 0.985 : 1,
    duration: const Duration(milliseconds: 110),
    child: LiteriaLeatherCard(
      semanticLabel: '${widget.title}. ${widget.subtitle}',
      padding: EdgeInsets.zero,
      onTap: widget.onTap,
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: SizedBox(
          height: widget.horizontal ? 108 : 204,
          child: widget.horizontal
              ? Row(
                  children: [
                    SizedBox(
                      width: 118,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(widget.asset, fit: BoxFit.contain),
                      ),
                    ),
                    Expanded(child: _TileLabel(widget: widget)),
                  ],
                )
              : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Image.asset(widget.asset, fit: BoxFit.contain),
                      ),
                    ),
                    _TileLabel(widget: widget),
                  ],
                ),
        ),
      ),
    ),
  );
}

class _TileLabel extends StatelessWidget {
  const _TileLabel({required this.widget});

  final _LiteriaActionTile widget;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: BookLeatherColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: BookLeatherColors.mutedForeground,
          ),
        ),
      ],
    ),
  );
}

class _ContinueGrid extends StatelessWidget {
  const _ContinueGrid({
    required this.lastManuscript,
    required this.lastReading,
    required this.onWrite,
    required this.onRead,
  });

  final BookProject? lastManuscript;
  final BookProject? lastReading;
  final VoidCallback onWrite;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ContinueCard(project: lastManuscript, writing: true, onTap: onWrite),
      _ContinueCard(project: lastReading, writing: false, onTap: onRead),
    ];
    if (MediaQuery.sizeOf(context).width < 700) {
      return Column(
        children: [cards.first, const SizedBox(height: 8), cards.last],
      );
    }
    return Row(
      children: [
        Expanded(child: cards.first),
        const SizedBox(width: 10),
        Expanded(child: cards.last),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.project,
    required this.writing,
    required this.onTap,
  });

  final BookProject? project;
  final bool writing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final title = writing ? strings.continueWriting : strings.continueReading;
    final emptyAction = writing
        ? strings.createFirstManuscript
        : strings.importFirstBook;
    final progress = project == null ? 0.0 : readingProgress(project!);
    return LiteriaLeatherCard(
      onTap: onTap,
      semanticLabel: title,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          if (project != null)
            BookCoverView(project: project!, width: 46, height: 64)
          else
            Container(
              width: 46,
              height: 64,
              decoration: BoxDecoration(
                color: BookLeatherColors.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                writing ? Icons.edit_note : Icons.file_download,
                color: BookLeatherColors.accent,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: BookLeatherColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  project?.metadata.title ?? emptyAction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: BookLeatherColors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!writing && project != null) ...[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    color: BookLeatherColors.accent,
                    backgroundColor: BookLeatherColors.stitch.withValues(
                      alpha: 0.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: BookLeatherColors.foreground),
        ],
      ),
    );
  }
}
