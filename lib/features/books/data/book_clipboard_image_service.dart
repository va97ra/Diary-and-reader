import 'package:dnevnik/features/books/application/book_image_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quill_native_bridge/quill_native_bridge.dart';

class BookClipboardImageService implements BookClipboardImageGateway {
  const BookClipboardImageService();

  static const _androidChannel = MethodChannel('literia/book_files');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> hasImage() async {
    try {
      if (_isAndroid) {
        return await _androidChannel.invokeMethod<bool>('hasClipboardImage') ??
            false;
      }
      return await QuillNativeBridge().isSupported(
        QuillNativeBridgeFeature.getClipboardImage,
      );
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Returns null when the clipboard has no image; throws [PlatformException]
  /// when an image exists but cannot be read.
  @override
  Future<BookImageFile?> read() async {
    try {
      if (_isAndroid) {
        final result = await _androidChannel.invokeMapMethod<String, Object?>(
          'readClipboardImage',
        );
        final bytes = result?['bytes'];
        if (bytes is! Uint8List || bytes.isEmpty) return null;
        return BookImageFile(
          name: result?['name']?.toString() ?? 'clipboard-image',
          bytes: bytes,
        );
      }
      final bridge = QuillNativeBridge();
      if (!await bridge.isSupported(
        QuillNativeBridgeFeature.getClipboardImage,
      )) {
        return null;
      }
      final bytes = await bridge.getClipboardImage();
      if (bytes == null || bytes.isEmpty) return null;
      return BookImageFile(name: 'clipboard-image.png', bytes: bytes);
    } on MissingPluginException {
      return null;
    }
  }
}
