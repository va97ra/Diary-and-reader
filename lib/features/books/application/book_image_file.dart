import 'dart:typed_data';

import 'package:dnevnik/features/books/domain/book_asset.dart';

class BookImageFile {
  BookImageFile({required this.name, required Uint8List bytes})
    : bytes = Uint8List.fromList(bytes);

  final String name;
  final Uint8List bytes;
}

abstract interface class BookImageFileGateway {
  Future<BookImageFile?> open();
}

abstract final class BookImageFileCodec {
  static const maxBytes = 20 * 1024 * 1024;

  static BookAsset? createAsset(BookImageFile file, {String? id}) {
    if (file.bytes.isEmpty || file.bytes.length > maxBytes) return null;
    final mediaType = _mediaType(file.bytes);
    if (mediaType == null) return null;
    return BookAsset(
      id: id ?? 'image-${DateTime.now().microsecondsSinceEpoch}',
      mediaType: mediaType,
      bytes: file.bytes,
      sourcePath: file.name,
    );
  }

  static String? _mediaType(Uint8List bytes) {
    if (_startsWith(bytes, const [0x89, 0x50, 0x4E, 0x47])) {
      return 'image/png';
    }
    if (_startsWith(bytes, const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (_startsWith(bytes, const [0x47, 0x49, 0x46, 0x38])) {
      return 'image/gif';
    }
    if (bytes.length >= 12 &&
        _startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  static bool _startsWith(Uint8List bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) return false;
    }
    return true;
  }
}
