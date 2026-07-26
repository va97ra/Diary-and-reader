import 'dart:typed_data';

import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:image/image.dart' as image;

abstract final class BookCoverThumbnail {
  static const _maxWidth = 600;
  static const _maxHeight = 900;
  static const _maxStoredBytes = 320 * 1024;

  static BookProject compact(BookProject project) {
    final cover = project.coverAsset;
    if (cover == null || cover.bytes.length <= _maxStoredBytes) return project;
    final decoded = image.decodeImage(cover.bytes);
    if (decoded == null) return project;
    final oriented = image.bakeOrientation(decoded);
    final scale = [
      _maxWidth / oriented.width,
      _maxHeight / oriented.height,
      1.0,
    ].reduce((left, right) => left < right ? left : right);
    final resized = scale < 1
        ? image.copyResize(
            oriented,
            width: (oriented.width * scale).round(),
            height: (oriented.height * scale).round(),
            interpolation: image.Interpolation.average,
          )
        : oriented;
    final encoded = Uint8List.fromList(image.encodeJpg(resized, quality: 84));
    if (encoded.length >= cover.bytes.length) return project;
    final thumbnail = BookAsset(
      id: cover.id,
      mediaType: 'image/jpeg',
      bytes: encoded,
      sourcePath: cover.sourcePath,
    );
    return project.copyWith(assets: [thumbnail], coverAssetId: thumbnail.id);
  }
}
