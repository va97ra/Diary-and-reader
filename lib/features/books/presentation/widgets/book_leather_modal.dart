import 'package:dnevnik/features/books/presentation/widgets/book_adaptive_control_shell.dart';
import 'package:flutter/material.dart';

const double bookModalGrid = 8;
const double bookModalRadius = 20;

Future<T?> showBookLeatherBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  bool requestFocus = true,
}) {
  FocusManager.instance.primaryFocus?.unfocus(
    disposition: UnfocusDisposition.scope,
  );
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    requestFocus: requestFocus,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    elevation: 0,
    builder: (sheetContext) =>
        BookLeatherModalSurface(child: builder(sheetContext)),
  );
}

class BookLeatherModalSurface extends StatelessWidget {
  const BookLeatherModalSurface({
    required this.child,
    this.borderRadius = const BorderRadius.vertical(
      top: Radius.circular(bookModalRadius),
    ),
    this.safeArea = const EdgeInsets.only(left: 1, right: 1, bottom: 1),
    super.key,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsets safeArea;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: borderRadius,
    child: BookLeatherPanel(
      safeArea: safeArea,
      child: Theme(data: bookLeatherModalTheme(context), child: child),
    ),
  );
}

class BookLeatherModalHeader extends StatelessWidget {
  const BookLeatherModalHeader({
    required this.title,
    this.subtitle,
    this.onClose,
    this.closeKey,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 8, 8),
    super.key,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onClose;
  final Key? closeKey;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (subtitle case final String value) ...[
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: bookModalGrid),
          trailing!,
        ],
        if (onClose != null)
          IconButton(
            key: closeKey,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
      ],
    ),
  );
}

class BookLeatherDialog extends StatelessWidget {
  const BookLeatherDialog({
    required this.title,
    required this.content,
    this.actions = const [],
    this.maxWidth = 520,
    super.key,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: const EdgeInsets.all(16),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: BookLeatherModalSurface(
        borderRadius: BorderRadius.circular(16),
        safeArea: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DefaultTextStyle.merge(
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                child: title,
              ),
              const SizedBox(height: 12),
              Flexible(child: SingleChildScrollView(child: content)),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: bookModalGrid,
                  runSpacing: bookModalGrid,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

ThemeData bookLeatherModalTheme(BuildContext context) {
  final base = Theme.of(context);
  const foreground = BookLeatherColors.foreground;
  const muted = BookLeatherColors.mutedForeground;
  const panel = Color(0xD9271710);
  const field = Color(0xA61B0F0A);
  final outline = BookLeatherColors.stitch.withValues(alpha: 0.55);
  final scheme = const ColorScheme.dark(
    primary: BookLeatherColors.accent,
    onPrimary: BookLeatherColors.backgroundDark,
    secondary: BookLeatherColors.accent,
    onSecondary: BookLeatherColors.backgroundDark,
    surface: panel,
    onSurface: foreground,
    error: Color(0xFFFF8A80),
    onError: Color(0xFF3B0907),
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: outline),
  );
  return base.copyWith(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: panel,
    dividerColor: outline,
    textTheme: base.textTheme.apply(
      bodyColor: foreground,
      displayColor: foreground,
    ),
    iconTheme: const IconThemeData(color: foreground),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      labelStyle: const TextStyle(color: muted),
      hintStyle: TextStyle(color: muted.withValues(alpha: 0.78)),
      helperStyle: const TextStyle(color: muted),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(
          color: BookLeatherColors.accent,
          width: 1.4,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: const Color(0x8A1B0F0A),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: outline),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: foreground,
      textColor: foreground,
      dense: true,
      minVerticalPadding: 8,
      contentPadding: EdgeInsets.symmetric(horizontal: 12),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: BookLeatherColors.backgroundDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BookLeatherColors.accent,
        foregroundColor: BookLeatherColors.backgroundDark,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        side: BorderSide(color: outline),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
  );
}
