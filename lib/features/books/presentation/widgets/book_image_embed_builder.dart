import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_image_placement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

typedef BookImageTapCallback =
    void Function(
      QuillController controller,
      int offset,
      BookImagePlacement placement,
    );

class BookImageEmbedBuilder extends EmbedBuilder {
  const BookImageEmbedBuilder(this.assets, {this.onTap});

  final Iterable<BookAsset> assets;
  final BookImageTapCallback? onTap;

  @override
  String get key => 'bookImage';

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
    final image = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: switch (placement.alignment) {
            BookImageAlignment.left => Alignment.centerLeft,
            BookImageAlignment.center => Alignment.center,
            BookImageAlignment.right => Alignment.centerRight,
          },
          child: SizedBox(
            width: constraints.maxWidth * placement.widthPercent / 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 440),
                  child: Image.memory(
                    asset.bytes,
                    key: ValueKey('book-image-${asset.id}'),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => const SizedBox(
                      height: 96,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  ),
                ),
                if (placement.caption.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    placement.caption,
                    textAlign: TextAlign.center,
                    style: embedContext.textStyle.copyWith(
                      fontSize: embedContext.textStyle.fontSize == null
                          ? 12
                          : embedContext.textStyle.fontSize! * 0.82,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    final callback = onTap;
    if (callback == null || embedContext.readOnly) return image;
    return Semantics(
      button: true,
      label: AppStrings.of(context).illustrationSettings,
      child: InkWell(
        key: ValueKey('book-image-action-${asset.id}'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => callback(
          embedContext.controller,
          embedContext.node.documentOffset,
          placement,
        ),
        child: image,
      ),
    );
  }
}
