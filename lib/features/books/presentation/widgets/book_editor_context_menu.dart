import 'dart:math' as math;

import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/presentation/book_text_colors.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_image_editing_scope.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_text_color_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// The menu of selected words in the editor: the regular copy and paste
/// menu above the words, with "Paste image" when the clipboard holds a
/// picture, and the words' formatting right below them. Android hides its
/// own Paste item when the clipboard has no text, so without that entry a
/// copied picture could not be pasted at all.
class BookEditorContextMenu extends StatefulWidget {
  const BookEditorContextMenu({
    required this.state,
    required this.clipboardHasImage,
    required this.onPasteImage,
    super.key,
  });

  final QuillRawEditorState state;
  final Future<bool> Function() clipboardHasImage;
  final BookImagePasteCallback onPasteImage;

  @override
  State<BookEditorContextMenu> createState() => _BookEditorContextMenuState();
}

class _BookEditorContextMenuState extends State<BookEditorContextMenu> {
  bool _hasImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.state.widget.config.readOnly) return;
    widget.clipboardHasImage().then((hasImage) {
      if (mounted && hasImage) setState(() => _hasImage = true);
    });
  }

  bool get _canFormat =>
      !widget.state.widget.config.readOnly &&
      !widget.state.controller.selection.isCollapsed;

  @override
  Widget build(BuildContext context) {
    final items = [...widget.state.contextMenuButtonItems];
    if (_hasImage) {
      final pasteIndex = items.indexWhere(
        (item) => item.type == ContextMenuButtonType.paste,
      );
      items.insert(
        pasteIndex < 0 ? items.length : pasteIndex + 1,
        ContextMenuButtonItem(
          label: AppStrings.of(context).pasteImage,
          onPressed: () {
            final controller = widget.state.controller;
            widget.state.hideToolbar();
            widget.onPasteImage(controller);
          },
        ),
      );
    }
    final anchors = widget.state.contextMenuAnchors;
    final mediaQuery = MediaQuery.of(context);
    return TextFieldTapRegion(
      child: Stack(
        children: [
          Positioned.fill(
            child: AdaptiveTextSelectionToolbar.buttonItems(
              buttonItems: items,
              anchors: anchors,
            ),
          ),
          if (_canFormat)
            Positioned.fill(
              child: CustomSingleChildLayout(
                delegate: _BelowSelectionLayout(
                  anchors: anchors,
                  padding: mediaQuery.padding.copyWith(
                    bottom: math.max(
                      mediaQuery.padding.bottom,
                      mediaQuery.viewInsets.bottom,
                    ),
                  ),
                ),
                child: BookSelectionFormattingBar(
                  controller: widget.state.controller,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Places the formatting bar right below the selected words, clear of the
/// selection handles and of the copy menu, which drops below the words when
/// there is no room above them. With no room below either, the bar goes
/// above the words and the menu.
class _BelowSelectionLayout extends SingleChildLayoutDelegate {
  _BelowSelectionLayout({required this.anchors, required this.padding});

  final TextSelectionToolbarAnchors anchors;
  final EdgeInsets padding;

  static const _margin = 8.0;

  /// The Material copy menu and its distance from the words.
  static const _menu = 44.0 + 8.0;

  /// Room for the handles that hang below the selected words.
  static const _handles = 24.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          math.max(0, constraints.maxWidth - _margin * 2),
          constraints.maxHeight,
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final top = padding.top + _margin;
    final bottom = size.height - padding.bottom - _margin;
    final above = anchors.primaryAnchor;
    final below = anchors.secondaryAnchor ?? above;
    final menuBelow = above.dy - _menu < top;
    var y = below.dy + _handles + (menuBelow ? _menu : 0);
    if (y + childSize.height > bottom) {
      y = above.dy - (menuBelow ? 0 : _menu) - _margin - childSize.height;
    }
    final x = above.dx - childSize.width / 2;
    return Offset(
      x.clamp(
        _margin,
        math.max(_margin, size.width - _margin - childSize.width),
      ),
      y.clamp(top, math.max(top, bottom - childSize.height)),
    );
  }

  @override
  bool shouldRelayout(_BelowSelectionLayout oldDelegate) =>
      anchors.primaryAnchor != oldDelegate.anchors.primaryAnchor ||
      anchors.secondaryAnchor != oldDelegate.anchors.secondaryAnchor ||
      padding != oldDelegate.padding;
}

/// Bold, italic, underlined, struck through and the colour of the selected
/// words, so that they need not open the formatting sheet. The colour shows
/// its palette in place of the buttons; the bar stays up for the next
/// change.
class BookSelectionFormattingBar extends StatefulWidget {
  const BookSelectionFormattingBar({required this.controller, super.key});

  final QuillController controller;

  @override
  State<BookSelectionFormattingBar> createState() =>
      _BookSelectionFormattingBarState();
}

class _BookSelectionFormattingBarState
    extends State<BookSelectionFormattingBar> {
  bool _choosingColor = false;

  void _toggle(Attribute<dynamic> attribute) {
    final controller = widget.controller;
    final on = controller.getSelectionStyle().attributes.containsKey(
      attribute.key,
    );
    controller.formatSelection(
      on ? Attribute.clone(attribute, null) : attribute,
    );
  }

  void _color(String hex) {
    applyBookTextColor(widget.controller, hex);
    setState(() => _choosingColor = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: const ValueKey('selection-formatting-bar'),
      color: scheme.surfaceContainerHigh,
      elevation: 4,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: _choosingColor ? _palette(context) : _buttons(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buttons(BuildContext context) {
    final strings = AppStrings.of(context);
    final style = widget.controller.getSelectionStyle().attributes;
    Widget toggle(Attribute<dynamic> attribute, IconData icon, String label) =>
        _BarButton(
          key: ValueKey('selection-format-${attribute.key}'),
          icon: icon,
          label: label,
          selected: style.containsKey(attribute.key),
          onPressed: () => _toggle(attribute),
        );
    return [
      toggle(Attribute.bold, Icons.format_bold, strings.boldText),
      toggle(Attribute.italic, Icons.format_italic, strings.italicText),
      toggle(
        Attribute.underline,
        Icons.format_underlined,
        strings.underlineText,
      ),
      toggle(
        Attribute.strikeThrough,
        Icons.format_strikethrough,
        strings.strikeText,
      ),
      _BarButton(
        key: const ValueKey('selection-format-color'),
        icon: Icons.format_color_text,
        iconColor: bookTextColorOf(bookTextColorAt(widget.controller)),
        label: strings.textColor,
        onPressed: () => setState(() => _choosingColor = true),
      ),
    ];
  }

  List<Widget> _palette(BuildContext context) {
    final strings = AppStrings.of(context);
    final current = bookTextColorAt(widget.controller);
    return [
      for (final (hex, name) in [
        ('', strings.noTextColor),
        for (final (id, color) in BookTextColors.palette)
          (BookTextColors.hex(color), strings.textColorName(id)),
      ])
        Semantics(
          button: true,
          selected: hex == current,
          label: name,
          child: Tooltip(
            message: name,
            excludeFromSemantics: true,
            child: InkResponse(
              key: ValueKey('selection-color-${hex.isEmpty ? 'none' : hex}'),
              radius: 18,
              onTap: () => _color(hex),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: BookTextColorSwatch(hex: hex, size: 20),
              ),
            ),
          ),
        ),
      _BarButton(
        icon: Icons.close,
        label: MaterialLocalizations.of(context).closeButtonTooltip,
        onPressed: () => setState(() => _choosingColor = false),
      ),
    ];
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: label,
      isSelected: selected,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : iconColor ?? scheme.onSurface,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? scheme.primary : null,
        ),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}
