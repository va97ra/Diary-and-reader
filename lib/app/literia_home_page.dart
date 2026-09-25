import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_library_query.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_adaptive_control_shell.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_cover_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final hasSomethingToContinue =
        lastManuscript != null || lastReading != null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: bookStatusBarStyle(Brightness.dark),
      child: Scaffold(
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
                          _HomeHeader(strings: strings, onSettings: onSettings),
                          const SizedBox(height: 14),
                          // A returning reader or writer starts right here.
                          if (hasSomethingToContinue) ...[
                            _ContinueGrid(
                              lastManuscript: lastManuscript,
                              lastReading: lastReading,
                              onWrite: onContinueWriting,
                              onRead: onContinueReading,
                            ),
                            const SizedBox(height: 10),
                          ],
                          _PrimaryTiles(
                            availableWidth: constraints.maxWidth - 24,
                            textScale: MediaQuery.textScalerOf(
                              context,
                            ).scale(1),
                            onWrite: onWrite,
                            onRead: onRead,
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
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.strings, required this.onSettings});

  final AppStrings strings;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Stack(
        alignment: Alignment.center,
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
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              key: const ValueKey('home-settings-button'),
              tooltip: strings.settings,
              onPressed: onSettings,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0x66160B07),
                foregroundColor: BookLeatherColors.foreground,
              ),
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
        ],
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
    super.key,
  });

  final String title;
  final String subtitle;
  final String asset;
  final VoidCallback onTap;

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
          height: 204,
          child: Column(
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

/// The books to return to; a missing one simply leaves no card behind.
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
      if (lastManuscript case final project?)
        _ContinueCard(project: project, writing: true, onTap: onWrite),
      if (lastReading case final project?)
        _ContinueCard(project: project, writing: false, onTap: onRead),
    ];
    if (cards.length == 1) return cards.single;
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

  final BookProject project;
  final bool writing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final title = writing ? strings.continueWriting : strings.continueReading;
    return LiteriaLeatherCard(
      onTap: onTap,
      semanticLabel: '$title: ${project.metadata.title}',
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          BookCoverView(project: project, width: 46, height: 64),
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
                  project.metadata.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: BookLeatherColors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!writing) ...[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: readingProgress(project),
                    minHeight: 3,
                    color: BookLeatherColors.accent,
                    backgroundColor: BookLeatherColors.progressTrack,
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
