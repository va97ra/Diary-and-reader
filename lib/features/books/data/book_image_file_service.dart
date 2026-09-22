import 'package:dnevnik/features/books/application/book_image_file.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class BookImageFileService implements BookImageFileGateway {
  const BookImageFileService();

  static const _imageTypes = XTypeGroup(
    label: 'Images',
    extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp'],
    mimeTypes: ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
    uniformTypeIdentifiers: ['public.image'],
  );

  static bool get _usesPhotoPicker =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<BookImageFile?> open() async {
    final file = _usesPhotoPicker
        ? await ImagePicker().pickImage(
            source: ImageSource.gallery,
            requestFullMetadata: false,
          )
        : await openFile(acceptedTypeGroups: const [_imageTypes]);
    if (file == null) return null;
    return BookImageFile(name: file.name, bytes: await file.readAsBytes());
  }
}
