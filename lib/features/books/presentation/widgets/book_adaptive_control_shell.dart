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

class LiteriaLeatherAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const LiteriaLeatherAppBar({
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    super.key,
  });

  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    title: title,
    actions: actions,
    leading: leading,
    automaticallyImplyLeading: automaticallyImplyLeading,
    foregroundColor: BookLeatherColors.foreground,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    flexibleSpace: const BookLeatherPanel(
      safeArea: EdgeInsets.only(top: 1, left: 1, right: 1),
      child: SizedBox.expand(),
    ),
  );
}

class LiteriaParchmentBackground extends StatelessWidget {
  const LiteriaParchmentBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1B100B) : const Color(0xFFF3E7D3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF21130D), Color(0xFF160C08)]
              : const [Color(0xFFFFF8EA), Color(0xFFEAD9BE)],
        ),
      ),
      child: child,
    );
  }
}

class LiteriaLeatherCard extends StatelessWidget {
  const LiteriaLeatherCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 14,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BookLeatherPanel(
          child: onTap == null
              ? content
              : Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: onTap, child: content),
                ),
        ),
      ),
    );
  }
}

class LiteriaCompactActionTile extends StatelessWidget {
  const LiteriaCompactActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing = const Icon(Icons.chevron_right),
    this.enabled = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled
        ? BookLeatherColors.foreground
        : BookLeatherColors.disabled;
    return Semantics(
      button: true,
      enabled: enabled,
      label: subtitle == null ? title : '$title. $subtitle',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0x38140A05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: BookLeatherColors.stitch.withValues(alpha: 0.38),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: foreground),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    if (subtitle case final value?)
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BookLeatherColors.mutedForeground,
                          fontSize: 11,
                          height: 1.15,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                IconTheme(
                  data: IconThemeData(size: 18, color: foreground),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
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
        constraints: BoxConstraints(minWidth: 44, minHeight: compact ? 48 : 56),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 2 : 6,
          vertical: compact ? 3 : 6,
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
              data: IconThemeData(size: compact ? 18 : 21, color: color),
              child: icon,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: compact ? compactLabelLines : 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: compact ? 9 : 10.5,
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
