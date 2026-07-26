import 'package:flutter/material.dart';

const double bookControlBreakpoint = 700;

abstract final class BookLeatherColors {
  static const background = Color(0xFF3B261B);
  static const backgroundDark = Color(0xFF24160F);
  static const foreground = Color(0xFFFFF4E6);
  static const mutedForeground = Color(0xFFD8C3AD);
  static const accent = Color(0xFFFBBF24);
  static const disabled = Color(0xFF927D6B);
  static const stitch = Color(0xFFB58A5A);
}

class BookAdaptiveControlShell extends StatelessWidget {
  const BookAdaptiveControlShell({
    required this.content,
    required this.compactTopPanel,
    required this.compactBottomPanel,
    required this.wideStartPanel,
    required this.wideEndPanel,
    this.panelsVisible = true,
    super.key,
  });

  final Widget content;
  final Widget compactTopPanel;
  final Widget compactBottomPanel;
  final Widget wideStartPanel;
  final Widget wideEndPanel;
  final bool panelsVisible;

  @override
  Widget build(BuildContext context) {
    if (!panelsVisible) return Scaffold(body: content);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < bookControlBreakpoint;
        if (compact) {
          return Scaffold(
            body: Column(
              children: [
                BookLeatherPanel(
                  key: const ValueKey('book-compact-top-panel'),
                  safeArea: const EdgeInsets.only(top: 1, left: 1, right: 1),
                  child: compactTopPanel,
                ),
                Expanded(child: content),
              ],
            ),
            bottomNavigationBar: BookLeatherPanel(
              key: const ValueKey('book-compact-bottom-panel'),
              safeArea: const EdgeInsets.only(bottom: 1, left: 1, right: 1),
              child: compactBottomPanel,
            ),
          );
        }
        final panelWidth = constraints.maxWidth >= 1200 ? 176.0 : 128.0;
        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: panelWidth,
                child: BookLeatherPanel(
                  key: const ValueKey('book-wide-start-panel'),
                  safeArea: const EdgeInsets.only(top: 1, bottom: 1, left: 1),
                  child: wideStartPanel,
                ),
              ),
              Expanded(child: content),
              SizedBox(
                width: panelWidth,
                child: BookLeatherPanel(
                  key: const ValueKey('book-wide-end-panel'),
                  safeArea: const EdgeInsets.only(top: 1, right: 1, bottom: 1),
                  child: wideEndPanel,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class BookLeatherPanel extends StatelessWidget {
  const BookLeatherPanel({
    required this.child,
    this.safeArea = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsets safeArea;

  @override
  Widget build(BuildContext context) => Material(
    color: BookLeatherColors.background,
    child: Stack(
      fit: StackFit.passthrough,
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: BookLeatherColors.background,
              image: DecorationImage(
                image: AssetImage('assets/ui/leather-dark.webp'),
                fit: BoxFit.none,
                repeat: ImageRepeat.repeat,
                opacity: 0.78,
                colorFilter: ColorFilter.mode(
                  Color(0x3D000000),
                  BlendMode.multiply,
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x253A2518), Color(0x5C160C07)],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: const _LeatherStitchPainter()),
          ),
        ),
        SafeArea(
          top: safeArea.top > 0,
          right: safeArea.right > 0,
          bottom: safeArea.bottom > 0,
          left: safeArea.left > 0,
          child: IconTheme(
            data: const IconThemeData(color: BookLeatherColors.foreground),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: BookLeatherColors.foreground),
              child: child,
            ),
          ),
        ),
      ],
    ),
  );
}

class BookPanelAction extends StatelessWidget {
  const BookPanelAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.selected = false,
    this.compact = false,
    this.compactLabelLines = 1,
    super.key,
  });

  final Widget icon;
  final String label;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final bool selected;
  final bool compact;
  final int compactLabelLines;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = !enabled
        ? BookLeatherColors.disabled
        : selected
        ? BookLeatherColors.accent
        : BookLeatherColors.foreground;
    final action = InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        constraints: BoxConstraints(minWidth: 48, minHeight: compact ? 52 : 60),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 3 : 6,
          vertical: compact ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? BookLeatherColors.accent.withValues(alpha: 0.14)
              : const Color(0x26140A05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? BookLeatherColors.accent.withValues(alpha: 0.72)
                : BookLeatherColors.stitch.withValues(alpha: 0.28),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(size: compact ? 20 : 22, color: color),
              child: icon,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: compact ? compactLabelLines : 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: compact ? 9.5 : 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                height: 1.08,
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: semanticLabel ?? label,
      child: Tooltip(message: semanticLabel ?? label, child: action),
    );
  }
}

class BookPanelIconAction extends StatelessWidget {
  const BookPanelIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    color: BookLeatherColors.foreground,
    icon: Icon(icon),
  );
}

class BookPanelSectionLabel extends StatelessWidget {
  const BookPanelSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 8, 5),
    child: Text(
      label.toUpperCase(),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: BookLeatherColors.mutedForeground,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
      ),
    ),
  );
}

class BookPanelTitleAction extends StatelessWidget {
  const BookPanelTitleAction({
    required this.title,
    required this.label,
    this.onPressed,
    this.primary = false,
    super.key,
  });

  final String title;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final titleWidget = Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primary
                  ? BookLeatherColors.foreground
                  : BookLeatherColors.mutedForeground,
              fontSize: primary ? 15 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onPressed != null) ...[
          const SizedBox(width: 3),
          Icon(
            Icons.edit_outlined,
            size: 12,
            color: BookLeatherColors.mutedForeground.withValues(alpha: 0.9),
          ),
        ],
      ],
    );
    if (onPressed == null) return titleWidget;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: '$label: $title',
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: titleWidget,
          ),
        ),
      ),
    );
  }
}

class _LeatherStitchPainter extends CustomPainter {
  const _LeatherStitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 10 || size.height < 10) return;
    final paint = Paint()
      ..color = BookLeatherColors.stitch.withValues(alpha: 0.45)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(5.5, 5.5, size.width - 11, size.height - 11);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 3.5), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LeatherStitchPainter oldDelegate) => false;
}
