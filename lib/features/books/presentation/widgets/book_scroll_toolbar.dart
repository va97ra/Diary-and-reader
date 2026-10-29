import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A writer tool on the unfurled parchment, with an optional explanation.
class BookScrollAction {
  const BookScrollAction({
    required this.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.hint,
  });

  final Key key;
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onPressed;
}

/// Related tools sharing one small rolled-up handle.
class BookScrollGroup {
  const BookScrollGroup({
    required this.id,
    required this.label,
    required this.icon,
    required this.actions,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<BookScrollAction> actions;
}

/// Unfurls a handle-width icon strip above the text using a linked overlay.
/// The editor keeps its size and scroll position when tools are shown.
/// Back, the close button, the handle or choosing an action folds it away.
class BookScrollToolbar extends StatefulWidget {
  const BookScrollToolbar({
    required this.groups,
    required this.closeLabel,
    super.key,
  });

  final List<BookScrollGroup> groups;
  final String closeLabel;

  @override
  State<BookScrollToolbar> createState() => _BookScrollToolbarState();
}

class _BookScrollToolbarState extends State<BookScrollToolbar> {
  String? _openId;
  final _portal = OverlayPortalController();
  final _links = <String, LayerLink>{};
  bool _disposing = false;
  LocalHistoryEntry? _historyEntry;

  void _close() {
    _portal.hide();
    final entry = _historyEntry;
    _historyEntry = null;
    entry?.remove();
    if (mounted && _openId != null) setState(() => _openId = null);
  }

  void _toggle(BookScrollGroup group) {
    if (_openId == group.id) {
      _close();
      return;
    }
    if (_historyEntry == null) {
      _historyEntry = LocalHistoryEntry(
        onRemove: () {
          _historyEntry = null;
          if (mounted && !_disposing) {
            _portal.hide();
            setState(() => _openId = null);
          }
        },
      );
      ModalRoute.of(context)?.addLocalHistoryEntry(_historyEntry!);
    }
    setState(() => _openId = group.id);
    _portal.show();
  }

  @override
  void dispose() {
    // Removing this entry must not set state while the toolbar is unmounting.
    final entry = _historyEntry;
    _historyEntry = null;
    _disposing = true;
    entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final index = widget.groups.indexWhere((group) => group.id == _openId);
      final group = index < 0 ? null : widget.groups[index];
      final handleWidth = (constraints.maxWidth - 8) / widget.groups.length - 6;
      return TapRegion(
        groupId: this,
        onTapOutside: (_) => _close(),
        child: OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (context) {
            if (group == null) return const SizedBox.shrink();
            final reduceMotion = MediaQuery.disableAnimationsOf(context);
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: CompositedTransformFollower(
                    link: _links[group.id]!,
                    showWhenUnlinked: false,
                    targetAnchor: Alignment.topLeft,
                    followerAnchor: Alignment.bottomLeft,
                    child: TapRegion(
                      groupId: this,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(group.id),
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(
                          milliseconds: reduceMotion ? 0 : 220,
                        ),
                        curve: Curves.easeOutCubic,
                        builder: (context, amount, child) => ClipRect(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            heightFactor: amount,
                            widthFactor: 1,
                            child: child,
                          ),
                        ),
                        child: SizedBox(
                          width: handleWidth,
                          child: _buildStrip(context, group),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 5, 4, 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in widget.groups)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: CompositedTransformTarget(
                          link: _links.putIfAbsent(item.id, LayerLink.new),
                          child: _ScrollHandle(
                            group: item,
                            selected: item.id == _openId,
                            onPressed: () => _toggle(item),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _buildStrip(BuildContext context, BookScrollGroup group) => Material(
    key: ValueKey('writer-scroll-strip-${group.id}'),
    color: Colors.transparent,
    child: Container(
      constraints: BoxConstraints(
        maxHeight: math.min(
          360,
          (MediaQuery.sizeOf(context).height -
                  MediaQuery.viewInsetsOf(context).bottom) *
              0.5,
        ),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE6C68E), Color(0xFFFFF0CD), Color(0xFFE6C68E)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _ScrollRod(),
          Flexible(
            child: ListView(
              key: ValueKey('writer-scroll-actions-${group.id}'),
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              children: [
                for (final action in group.actions)
                  SizedBox(
                    height: 52,
                    child: IconButton(
                      key: action.key,
                      tooltip: action.hint == null
                          ? action.label
                          : '${action.label}\n${action.hint}',
                      color: _ink,
                      icon: Icon(action.icon, size: 26),
                      onPressed: () {
                        _close();
                        action.onPressed();
                      },
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            child: IconButton(
              key: const ValueKey('writer-scroll-close'),
              tooltip: widget.closeLabel,
              color: _ink,
              onPressed: _close,
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
        ],
      ),
    ),
  );
}

const _ink = Color(0xFF382617);

class _ScrollHandle extends StatelessWidget {
  const _ScrollHandle({
    required this.group,
    required this.selected,
    required this.onPressed,
  });

  final BookScrollGroup group;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    expanded: selected,
    child: InkWell(
      key: ValueKey('writer-scroll-${group.id}'),
      borderRadius: BorderRadius.circular(10),
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60, minWidth: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _ScrollRod(),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFFE2A1)
                    : const Color(0xFFE8C998),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(6),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(group.icon, color: _ink, size: 21),
                  const SizedBox(height: 2),
                  Text(
                    group.label,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The lit cylindrical edge makes the parchment read as a roll, not a card.
class _ScrollRod extends StatelessWidget {
  const _ScrollRod();

  @override
  Widget build(BuildContext context) => Container(
    height: 8,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFEDC0), Color(0xFFBC8B49), Color(0xFFF3D59F)],
      ),
    ),
  );
}
