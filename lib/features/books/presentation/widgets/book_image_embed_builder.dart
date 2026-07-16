import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookImageEmbedBuilder extends EmbedBuilder {
  const BookImageEmbedBuilder(this.assets);

  final Iterable<BookAsset> assets;

  @override
  String get key => 'bookImage';

  @override
  String toPlainText(Embed node) => Embed.kObjectReplacementCharacter;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final assetId = embedContext.node.value.data.toString();
    final asset = assets.where((item) => item.id == assetId).firstOrNull;
    if (asset == null || !asset.isRenderableImage) {
      return const SizedBox(
        height: 96,
        child: Center(child: Icon(Icons.broken_image_outlined)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: ConstrainedBox(
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
      ),
    );
  }
}
