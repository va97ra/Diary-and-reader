import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_library_query.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
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
    required this.showOnboarding,
    required this.onDismissOnboarding,
    super.key,
  });

  final BookProject? lastManuscript;
  final BookProject? lastReading;
  final VoidCallback onWrite;
  final VoidCallback onRead;
  final VoidCallback onSettings;
  final VoidCallback onContinueWriting;
  final VoidCallback onContinueReading;
  final bool showOnboarding;
  final VoidCallback onDismissOnboarding;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/home/desk-background.webp',
            fit: BoxFit.cover,
            semanticLabel: '',
          ),
          ColoredBox(
            color: dark ? const Color(0x99060A13) : const Color(0x3DFFF4DF),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HomeHeader(strings: strings),
                        if (showOnboarding) ...[
                          const SizedBox(height: 16),
                          _QuickStartCard(onDismiss: onDismissOnboarding),
                        ],
                        const SizedBox(height: 22),
                        _PrimaryTiles(
                          availableWidth: constraints.maxWidth - 36,
                          textScale: MediaQuery.textScalerOf(context).scale(1),
                          onWrite: onWrite,
                          onRead: onRead,
                        ),
                        const SizedBox(height: 14),
                        _LiteriaActionTile(
                          key: const ValueKey('home-settings-tile'),
                          title: strings.settings,
                          subtitle: strings.settingsSubtitle,
                          asset: 'assets/home/organizer.webp',
                          onTap: onSettings,
                          horizontal: true,
                        ),
                        const SizedBox(height: 24),
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

class _QuickStartCard extends StatelessWidget {
  const _QuickStartCard({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      key: const ValueKey('home-quick-start'),
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.auto_awesome_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.quickStart,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(strings.quickStartBody),
                ],
              ),
            ),
            TextButton(onPressed: onDismiss, child: Text(strings.understood)),
          ],
        ),
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
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          color: const Color(0xFFFFF5DB),
          fontFamily: 'PT Serif',
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 12)],
        ),
      ),
      const SizedBox(height: 6),
      Text(
        strings.homeTagline,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: const Color(0xFFECE4D5),
          shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
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
        children: [tiles.first, const SizedBox(height: 14), tiles.last],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: tiles.first),
        const SizedBox(width: 14),
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
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${widget.title}. ${widget.subtitle}',
    child: AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 110),
      child: Material(
        color: const Color(0xC91B2434),
        elevation: 10,
        shadowColor: Colors.black54,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          child: SizedBox(
            height: widget.horizontal ? 150 : 260,
            child: widget.horizontal
                ? Row(
                    children: [
                      SizedBox(
                        width: 150,
                        child: Image.asset(widget.asset, fit: BoxFit.contain),
                      ),
                      Expanded(child: _TileLabel(widget: widget)),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                          child: Image.asset(widget.asset, fit: BoxFit.contain),
                        ),
                      ),
                      _TileLabel(widget: widget),
                    ],
                  ),
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
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFFFFD77A),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          widget.subtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
        children: [cards.first, const SizedBox(height: 12), cards.last],
      );
    }
    return Row(
      children: [
        Expanded(child: cards.first),
        const SizedBox(width: 14),
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
    return Card(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (project != null)
                BookCoverView(project: project!, width: 52, height: 72)
              else
                Container(
                  width: 52,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(writing ? Icons.edit_note : Icons.file_download),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 5),
                    Text(
                      project?.metadata.title ?? emptyAction,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (!writing && project != null) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progress),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
