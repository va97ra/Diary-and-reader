import 'package:dnevnik/features/books/application/book_image_file.dart';
import 'package:file_selector/file_selector.dart';

class BookImageFileService implements BookImageFileGateway {
  const BookImageFileService();

  static const _imageTypes = XTypeGroup(
    label: 'Images',
    extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp'],
    mimeTypes: ['image/png', 'image/jpeg', 'image/gif', 'image/webp'],
    uniformTypeIdentifiers: ['public.image'],
  );

  @override
  Future<BookImageFile?> open() async {
    final file = await openFile(acceptedTypeGroups: const [_imageTypes]);
    if (file == null) return null;
    return BookImageFile(name: file.name, bytes: await file.readAsBytes());
  }
}
