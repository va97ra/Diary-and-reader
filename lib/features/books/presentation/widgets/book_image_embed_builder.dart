import 'dart:async';

import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_image_document_editing.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_image_placement.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_adaptive_control_shell.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_image_editing_scope.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookImageEmbedBuilder extends EmbedBuilder {
  const BookImageEmbedBuilder(this.assets, {this.onTap});

  final Iterable<BookAsset> assets;

  /// Opens the full illustration settings. Null makes the embed read-only,
  /// which the pagination measurement editor relies on.
  final BookImageTapCallback? onTap;

  @override
  String get key => BookImagePlacement.embedType;

  @override
  String toPlainText(Embed node) => Embed.kObjectReplacementCharacter;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final placement = BookImagePlacement.decode(
      embedContext.node.value.data.toString(),
    );
    final asset = assets
        .where((item) => item.id == placement.assetId)
        .firstOrNull;
    if (asset == null || !asset.isRenderableImage) {
      return const SizedBox(
        height: 96,
        child: Center(child: Icon(Icons.broken_image_outlined)),
      );
    }
    // On-page editing needs the embed's position in the document, which
    // Quill only provides for attached (direct) embeds.
    final interactive =
        onTap != null &&
        !embedContext.readOnly &&
        embedContext.node.parent != null;
    return BookImageEmbedView(
      asset: asset,
      placement: placement,
      controller: embedContext.controller,
      node: embedContext.node,
      textStyle: embedContext.textStyle,
      scope: interactive ? BookImageEditingScope.maybeOf(context) : null,
      onOpenSettings: interactive ? onTap : null,
    );
  }
}

class BookImageEmbedView extends StatefulWidget {
  const BookImageEmbedView({
    required this.asset,
    required this.placement,
    required this.controller,
    required this.node,
    required this.textStyle,
    this.scope,
    this.onOpenSettings,
    super.key,
  });

  final BookAsset asset;
  final BookImagePlacement placement;
  final QuillController controller;
  final Embed node;
  final TextStyle textStyle;
  final BookImageEditingScope? scope;
  final BookImageTapCallback? onOpenSettings;

  @override
  State<BookImageEmbedView> createState() => _BookImageEmbedViewState();
}

class _BookImageEmbedViewState extends State<BookImageEmbedView> {
  static const _minPercent = 20;
  static const _maxPercent = 100;
  static const _snapPercents = [25, 50, 75, 100];

  final _rowLink = LayerLink();
  final _toolbar = OverlayPortalController();
  double _rowWidth = 0;

  int? _previewPercent;
  int _resizeStartPercent = 100;
  double _resizeDistance = 0;

  OverlayEntry? _dragOverlay;
  RenderEditor? _dragEditor;
  Timer? _autoScroll;
  Offset _dragPointer = Offset.zero;
  int? _dropOffset;
  Offset? _dropLineStart;
  Offset? _dropLineEnd;

  BookImageSelection? get _selection => widget.scope?.selection;
  int get _offset => widget.node.documentOffset;
  bool get _selected =>
      _selection?.isSelected(widget.controller, _offset) ?? false;

  @override
  void initState() {
    super.initState();
    if (widget.scope != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _toolbar.show();
      });
    }
  }

  @override
  void dispose() {
    _finishDrag();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = _selection;
    if (selection == null) return _buildLayout(context, selected: false);
    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) => OverlayPortal(
        controller: _toolbar,
        overlayChildBuilder: _buildToolbarOverlay,
        child: _buildLayout(context, selected: _selected),
      ),
    );
  }

  Widget _buildLayout(BuildContext context, {required bool selected}) {
    final percent = _previewPercent ?? widget.placement.widthPercent;
    return CompositedTransformTarget(
      link: _rowLink,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _rowWidth = constraints.maxWidth;
            return Align(
              alignment: switch (widget.placement.alignment) {
                BookImageAlignment.left => Alignment.centerLeft,
                BookImageAlignment.center => Alignment.center,
                BookImageAlignment.right => Alignment.centerRight,
              },
              child: SizedBox(
                width: constraints.maxWidth * percent / 100,
                // A tall picture is narrower than its width when its height
                // is capped; it still keeps to its side.
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: switch (widget.placement.alignment) {
                    BookImageAlignment.left => CrossAxisAlignment.start,
                    BookImageAlignment.center => CrossAxisAlignment.center,
                    BookImageAlignment.right => CrossAxisAlignment.end,
                  },
                  children: [
                    if (widget.scope == null)
                      _buildImage()
                    else
                      _buildInteractiveImage(context, selected: selected),
                    if (widget.placement.caption.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.placement.caption,
                        textAlign: switch (widget.placement.alignment) {
                          BookImageAlignment.left => TextAlign.left,
                          BookImageAlignment.center => TextAlign.center,
                          BookImageAlignment.right => TextAlign.right,
                        },
                        style: widget.textStyle.copyWith(
                          fontSize: widget.textStyle.fontSize == null
                              ? 12
                              : widget.textStyle.fontSize! * 0.82,
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImage() => ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 440),
    child: Image.memory(
      widget.asset.bytes,
      key: ValueKey('book-image-${widget.asset.id}'),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      // Until the picture is decoded it has no size; a placeholder keeps the
      // illustration tappable and the text from jumping.
      frameBuilder: (context, child, frame, loadedSynchronously) =>
          frame == null && !loadedSynchronously
          ? const SizedBox(
              width: double.infinity,
              height: 120,
              child: ColoredBox(color: Color(0x14000000)),
            )
          : child,
      errorBuilder: (_, _, _) => const SizedBox(
        height: 96,
        child: Center(child: Icon(Icons.broken_image_outlined)),
      ),
    ),
  );

  Widget _buildInteractiveImage(
    BuildContext context, {
    required bool selected,
  }) {
    final strings = AppStrings.of(context);
    final dragging = _dragOverlay != null;
    return Semantics(
      button: true,
      selected: selected,
      label: strings.illustrationSettings,
      hint: strings.imageDragHint,
      child: GestureDetector(
        key: ValueKey('book-image-action-${widget.asset.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: selected ? _openSettings : _select,
        onLongPressStart: _startDrag,
        onLongPressMoveUpdate: (details) => _updateDrag(details.globalPosition),
        onLongPressEnd: (_) => _dropImage(),
        onLongPressCancel: _finishDrag,
        onScaleStart: selected ? (_) => _startResize() : null,
        onScaleUpdate: selected ? _updatePinch : null,
        onScaleEnd: selected ? (_) => _commitResize() : null,
        child: Opacity(
          opacity: dragging ? 0.35 : 1,
          child: Stack(
            children: [
              _buildImage(),
              if (selected) ...[
                const Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.fromBorderSide(
                          BorderSide(color: BookLeatherColors.accent, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
                for (final corner in const [
                  Alignment.topLeft,
                  Alignment.topRight,
                  Alignment.bottomLeft,
                  Alignment.bottomRight,
                ])
                  _buildResizeHandle(corner),
              ],
              if (_previewPercent case final percent?)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(child: _PercentBadge(percent: percent)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResizeHandle(Alignment corner) {
    final grows = corner.x > 0 ? 1.0 : -1.0;
    return Positioned(
      left: corner.x < 0 ? 0 : null,
      right: corner.x > 0 ? 0 : null,
      top: corner.y < 0 ? 0 : null,
      bottom: corner.y > 0 ? 0 : null,
      child: GestureDetector(
        key: ValueKey('image-resize-handle-${corner.x}-${corner.y}'),
        behavior: HitTestBehavior.opaque,
        // Count the finger travel from touch-down so the corner follows it.
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: (_) => _startResize(),
        onHorizontalDragUpdate: (details) =>
            _updateResize(details.delta.dx * grows),
        onHorizontalDragEnd: (_) => _commitResize(),
        onHorizontalDragCancel: _commitResize,
        child: SizedBox.square(
          dimension: 36,
          child: Align(
            alignment: corner,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: BookLeatherColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x55000000), blurRadius: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarOverlay(BuildContext context) {
    if (!_selected || _dragOverlay != null || _previewPercent != null) {
      return const SizedBox.shrink();
    }
    final scrollable = Scrollable.maybeOf(this.context, axis: Axis.vertical);
    Widget build(BuildContext context, Widget? _) {
      final placeBelow = _spaceAboveRow(scrollable) < 60;
      return Align(
        alignment: Alignment.topLeft,
        child: CompositedTransformFollower(
          link: _rowLink,
          showWhenUnlinked: false,
          targetAnchor: placeBelow
              ? Alignment.bottomCenter
              : Alignment.topCenter,
          followerAnchor: placeBelow
              ? Alignment.topCenter
              : Alignment.bottomCenter,
          offset: Offset(0, placeBelow ? 4 : -4),
          child: _ImageToolbar(
            placement: widget.placement,
            onAlign: (alignment) =>
                _apply(widget.placement.alignedTo(alignment)),
            onResize: (percent) =>
                _apply(widget.placement.copyWith(widthPercent: percent)),
            onOpenSettings: _openSettings,
            onDelete: _delete,
          ),
        ),
      );
    }

    // Re-evaluate the side on scroll so the toolbar never covers the header.
    final position = scrollable?.position;
    if (position == null) return build(context, null);
    return ListenableBuilder(listenable: position, builder: build);
  }

  /// Free space between the top of the scroll viewport and this illustration.
  double _spaceAboveRow(ScrollableState? scrollable) {
    final row = context.findRenderObject();
    if (row is! RenderBox || !row.attached) return double.infinity;
    final rowTop = row.localToGlobal(Offset.zero).dy;
    final viewport = scrollable?.context.findRenderObject();
    final viewportTop = viewport is RenderBox && viewport.attached
        ? viewport.localToGlobal(Offset.zero).dy
        : 0.0;
    return rowTop - viewportTop;
  }

  void _select() {
    _keepKeyboardClosed();
    FocusManager.instance.primaryFocus?.unfocus();
    _selection?.select(widget.controller, _offset);
  }

  /// Quill handles a tap even after the embed has won it, moving the cursor
  /// and opening the keyboard over the page; ask the editor to skip it.
  void _keepKeyboardClosed() => _selection?.swallowEditorTap();

  void _openSettings() {
    _keepKeyboardClosed();
    _selection?.clear();
    widget.onOpenSettings?.call(widget.controller, _offset, widget.placement);
  }

  void _apply(BookImagePlacement next) {
    if (next == widget.placement) return;
    final offset = _offset;
    _selection?.edit(
      widget.controller,
      () => BookImageDocumentEditing.replace(widget.controller, offset, next)
          ? offset
          : null,
    );
  }

  void _delete() {
    final controller = widget.controller;
    final offset = _offset;
    _selection?.edit(controller, () {
      BookImageDocumentEditing.remove(controller, offset);
      return null;
    });
  }

  // Resizing -----------------------------------------------------------------

  void _startResize() {
    _resizeStartPercent = widget.placement.widthPercent;
    _resizeDistance = 0;
  }

  void _updateResize(double grow) {
    if (_rowWidth <= 0) return;
    _resizeDistance += grow;
    final symmetric = widget.placement.alignment == BookImageAlignment.center;
    final widthChange = symmetric ? _resizeDistance * 2 : _resizeDistance;
    _setPreview(_resizeStartPercent + widthChange / _rowWidth * 100);
  }

  void _updatePinch(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;
    _setPreview(_resizeStartPercent * details.scale);
  }

  void _setPreview(double percent) {
    var next = percent.round().clamp(_minPercent, _maxPercent);
    for (final snap in _snapPercents) {
      if ((percent - snap).abs() < 2.5) next = snap;
    }
    if (next == _previewPercent) return;
    if (_snapPercents.contains(next)) HapticFeedback.selectionClick();
    setState(() => _previewPercent = next);
  }

  void _commitResize() {
    final percent = _previewPercent;
    if (percent == null) return;
    setState(() => _previewPercent = null);
    _apply(widget.placement.copyWith(widthPercent: percent));
  }

  // Dragging -----------------------------------------------------------------

  void _startDrag(LongPressStartDetails details) {
    final editor = context.findAncestorRenderObjectOfType<RenderEditor>();
    if (editor == null || _dragOverlay != null) return;
    HapticFeedback.mediumImpact();
    FocusManager.instance.primaryFocus?.unfocus();
    _dragEditor = editor;
    _dragPointer = details.globalPosition;
    _dropOffset = null;
    final overlay = OverlayEntry(builder: _buildDragOverlay);
    setState(() => _dragOverlay = overlay);
    Overlay.of(context, rootOverlay: true).insert(overlay);
    _selection?.select(widget.controller, _offset);
    _updateDropTarget();
    _autoScroll = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _autoScrollTick(),
    );
  }

  void _updateDrag(Offset globalPosition) {
    if (_dragOverlay == null) return;
    _dragPointer = globalPosition;
    _updateDropTarget();
  }

  void _dropImage() {
    final target = _dropOffset;
    final from = _offset;
    _finishDrag();
    if (target == null) return;
    final controller = widget.controller;
    _selection?.edit(
      controller,
      () => BookImageDocumentEditing.move(controller, from, target) ?? from,
    );
  }

  void _finishDrag() {
    _autoScroll?.cancel();
    _autoScroll = null;
    final overlay = _dragOverlay;
    if (overlay == null) return;
    overlay.remove();
    overlay.dispose();
    _dragEditor = null;
    if (mounted) {
      setState(() => _dragOverlay = null);
    } else {
      _dragOverlay = null;
    }
  }

  /// Finds the paragraph boundary nearest to the finger: the illustration is
  /// dropped either before or after the paragraph under the pointer.
  void _updateDropTarget() {
    final editor = _dragEditor;
    if (editor == null || !editor.attached || !editor.hasSize) return;
    final local = editor.globalToLocal(_dragPointer);
    final probe = Offset(
      local.dx.clamp(1, editor.size.width - 1),
      local.dy.clamp(0, editor.size.height - 1),
    );
    final position = editor.getPositionForOffset(editor.localToGlobal(probe));
    final text = widget.controller.document.toPlainText();
    if (text.isEmpty) return;
    final offset = position.offset.clamp(0, text.length - 1);
    final lineStart = offset == 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;
    var lineEnd = text.indexOf('\n', offset);
    if (lineEnd < 0) lineEnd = text.length - 1;
    final top = editor
        .getLocalRectForCaret(TextPosition(offset: lineStart))
        .top;
    final bottom = editor
        .getLocalRectForCaret(TextPosition(offset: lineEnd))
        .bottom;
    final before = probe.dy < (top + bottom) / 2;
    final y = before ? top : bottom;
    _dropOffset = before ? lineStart : lineEnd + 1;
    _dropLineStart = editor.localToGlobal(Offset(0, y));
    _dropLineEnd = editor.localToGlobal(Offset(editor.size.width, y));
    _dragOverlay?.markNeedsBuild();
  }

  void _autoScrollTick() {
    final scrollable = Scrollable.maybeOf(context, axis: Axis.vertical);
    final box = scrollable?.context.findRenderObject();
    if (scrollable == null || box is! RenderBox || !box.hasSize) return;
    const edge = 72.0;
    const maxStep = 14.0;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    final y = _dragPointer.dy;
    var delta = 0.0;
    if (y < top + edge) {
      delta = -maxStep * ((top + edge - y) / edge).clamp(0, 1);
    } else if (y > bottom - edge) {
      delta = maxStep * ((y - bottom + edge) / edge).clamp(0, 1);
    }
    if (delta == 0) return;
    final position = scrollable.position;
    final next = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (next == position.pixels) return;
    position.jumpTo(next);
    _updateDropTarget();
  }

  Widget _buildDragOverlay(BuildContext context) {
    final start = _dropLineStart;
    final end = _dropLineEnd;
    const ghostWidth = 110.0;
    return IgnorePointer(
      child: Stack(
        children: [
          if (start != null && end != null) ...[
            Positioned(
              key: const ValueKey('image-drop-indicator'),
              left: start.dx,
              top: start.dy - 1.5,
              width: (end.dx - start.dx).clamp(0, double.infinity),
              height: 3,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: BookLeatherColors.accent,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
            Positioned(
              left: start.dx - 5,
              top: start.dy - 5,
              width: 10,
              height: 10,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: BookLeatherColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
          Positioned(
            left: _dragPointer.dx - ghostWidth / 2,
            top: _dragPointer.dy - 96,
            width: ghostWidth,
            child: Opacity(
              opacity: 0.85,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: BookLeatherColors.accent, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66000000), blurRadius: 12),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 84),
                  child: Image.memory(
                    widget.asset.bytes,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
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

class _PercentBadge extends StatelessWidget {
  const _PercentBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey('image-resize-badge'),
    decoration: BoxDecoration(
      color: BookLeatherColors.backgroundDark.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        '$percent%',
        style: const TextStyle(
          color: BookLeatherColors.foreground,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
  );
}

class _ImageToolbar extends StatelessWidget {
  const _ImageToolbar({
    required this.placement,
    required this.onAlign,
    required this.onResize,
    required this.onOpenSettings,
    required this.onDelete,
  });

  final BookImagePlacement placement;
  final ValueChanged<BookImageAlignment> onAlign;
  final ValueChanged<int> onResize;
  final VoidCallback onOpenSettings;
  final VoidCallback onDelete;

  static const _step = 10;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final percent = placement.widthPercent;
    final smaller = ((percent - 1) ~/ _step * _step).clamp(20, 100);
    final larger = ((percent ~/ _step + 1) * _step).clamp(20, 100);
    return TextFieldTapRegion(
      child: Material(
        key: const ValueKey('image-inline-toolbar'),
        color: BookLeatherColors.backgroundDark,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: BookLeatherColors.stitch),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tool(
                key: 'image-align-left',
                icon: Icons.format_align_left,
                tooltip: strings.alignLeft,
                selected: placement.alignment == BookImageAlignment.left,
                onPressed: () => onAlign(BookImageAlignment.left),
              ),
              _tool(
                key: 'image-align-center',
                icon: Icons.format_align_center,
                tooltip: strings.alignCenter,
                selected: placement.alignment == BookImageAlignment.center,
                onPressed: () => onAlign(BookImageAlignment.center),
              ),
              _tool(
                key: 'image-align-right',
                icon: Icons.format_align_right,
                tooltip: strings.alignRight,
                selected: placement.alignment == BookImageAlignment.right,
                onPressed: () => onAlign(BookImageAlignment.right),
              ),
              _divider(),
              _tool(
                key: 'image-smaller',
                icon: Icons.remove,
                tooltip: strings.imageSmaller,
                onPressed: percent > 20 ? () => onResize(smaller) : null,
              ),
              SizedBox(
                width: 42,
                child: Text(
                  '$percent%',
                  key: const ValueKey('image-inline-size'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: BookLeatherColors.foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _tool(
                key: 'image-larger',
                icon: Icons.add,
                tooltip: strings.imageLarger,
                onPressed: percent < 100 ? () => onResize(larger) : null,
              ),
              _divider(),
              _tool(
                key: 'image-more-settings',
                icon: Icons.tune,
                tooltip: strings.imageMoreSettings,
                onPressed: onOpenSettings,
              ),
              _tool(
                key: 'image-inline-delete',
                icon: Icons.delete_outline,
                tooltip: strings.deleteImage,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => const SizedBox(
    height: 24,
    child: VerticalDivider(
      width: 9,
      thickness: 1,
      color: BookLeatherColors.stitch,
    ),
  );

  Widget _tool({
    required String key,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool selected = false,
  }) => IconButton(
    key: ValueKey(key),
    tooltip: tooltip,
    onPressed: onPressed,
    isSelected: selected,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints.tightFor(width: 36, height: 40),
    padding: EdgeInsets.zero,
    iconSize: 20,
    color: BookLeatherColors.foreground,
    selectedIcon: Icon(icon, color: BookLeatherColors.accent),
    disabledColor: BookLeatherColors.disabled,
    icon: Icon(icon),
  );
}
