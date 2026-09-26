import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_image_placement.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_settings_controls.dart';
import 'package:flutter/material.dart';

enum BookImageSettingsAction { save, moveToCursor, delete }

class BookImageSettingsSheet extends StatefulWidget {
  const BookImageSettingsSheet({
    required this.placement,
    required this.onChanged,
    required this.onReplace,
    super.key,
  });

  final BookImagePlacement placement;
  final ValueChanged<BookImagePlacement> onChanged;
  final Future<BookImagePlacement?> Function(BookImagePlacement) onReplace;

  @override
  State<BookImageSettingsSheet> createState() => _BookImageSettingsSheetState();
}

class _BookImageSettingsSheetState extends State<BookImageSettingsSheet> {
  late BookImagePlacement _placement;
  late final TextEditingController _captionController;
  late final FocusNode _captionFocusNode;
  bool _replacing = false;

  @override
  void initState() {
    super.initState();
    _placement = widget.placement;
    _captionController = TextEditingController(text: _placement.caption);
    _captionFocusNode = FocusNode(debugLabel: 'book-image-caption');
  }

  void _update(BookImagePlacement next) {
    if (next == _placement) return;
    setState(() => _placement = next);
    widget.onChanged(next);
  }

  void _updateFromControl(BookImagePlacement next) {
    _releaseCaptionFocus();
    _update(next);
  }

  void _releaseCaptionFocus() {
    _captionFocusNode.unfocus(disposition: UnfocusDisposition.scope);
  }

  Future<void> _replace() async {
    if (_replacing) return;
    setState(() => _replacing = true);
    final next = await widget.onReplace(_placement);
    if (!mounted) return;
    setState(() => _replacing = false);
    if (next != null) {
      setState(() => _placement = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookLeatherModalHeader(
              title: strings.illustrationSettings,
              onClose: () {
                _releaseCaptionFocus();
                Navigator.pop(context, BookImageSettingsAction.save);
              },
              closeKey: const ValueKey('image-settings-close'),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
            ),
            BookSettingsCard(
              title: strings.illustrationSettingsHint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BookCompactChoice<BookImageAlignment>(
                    key: const ValueKey('image-alignment-selector'),
                    label: strings.imagePosition,
                    value: _placement.alignment,
                    options: [
                      (
                        BookImageAlignment.left,
                        Icons.format_align_left,
                        strings.alignLeft,
                      ),
                      (
                        BookImageAlignment.center,
                        Icons.format_align_center,
                        strings.alignCenter,
                      ),
                      (
                        BookImageAlignment.right,
                        Icons.format_align_right,
                        strings.alignRight,
                      ),
                    ],
                    onChanged: (alignment) =>
                        _updateFromControl(_placement.alignedTo(alignment)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.imageSize,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          key: const ValueKey('image-size-slider'),
                          value: _placement.widthPercent.toDouble(),
                          min: 20,
                          max: 100,
                          label: '${_placement.widthPercent}%',
                          onChangeStart: (_) => _releaseCaptionFocus(),
                          onChanged: (value) => _update(
                            _placement.copyWith(widthPercent: value.round()),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${_placement.widthPercent}%',
                          key: const ValueKey('image-size-value'),
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    key: const ValueKey('image-caption-field'),
                    controller: _captionController,
                    focusNode: _captionFocusNode,
                    maxLength: 180,
                    minLines: 1,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: strings.imageCaption,
                      hintText: strings.imageCaptionHint,
                      counterText: '',
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onTapOutside: (_) => _releaseCaptionFocus(),
                    onChanged: (value) =>
                        _update(_placement.copyWith(caption: value)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.imageMoveHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              key: const ValueKey('move-image-to-cursor'),
              onPressed: () =>
                  Navigator.pop(context, BookImageSettingsAction.moveToCursor),
              icon: const Icon(Icons.vertical_align_center, size: 19),
              label: Text(strings.moveImageToCursor),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('replace-book-image'),
                    onPressed: _replacing ? null : _replace,
                    icon: _replacing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.swap_horiz, size: 19),
                    label: Text(strings.replaceImage),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('delete-book-image'),
                    onPressed: () =>
                        Navigator.pop(context, BookImageSettingsAction.delete),
                    icon: const Icon(Icons.delete_outline, size: 19),
                    label: Text(strings.deleteImage),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _captionFocusNode.dispose();
    _captionController.dispose();
    super.dispose();
  }
}
