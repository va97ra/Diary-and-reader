import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:file_selector/file_selector.dart';

abstract interface class BookImportFileGateway {
  Future<BookImportFile?> open();
}

class BookImportFileService implements BookImportFileGateway {
  const BookImportFileService();

  static const _bookTypes = XTypeGroup(
    label: 'Electronic books',
    extensions: ['epub', 'fb2', 'zip'],
    mimeTypes: [
      'application/epub+zip',
      'application/x-fictionbook+xml',
      'application/xml',
      'text/xml',
      'application/zip',
      'application/x-zip-compressed',
      // Android's Downloads provider often assigns this generic MIME type to
      // sideloaded FB2 files. The parser still validates the extension and
      // binary signature before accepting the book.
      'application/octet-stream',
    ],
    uniformTypeIdentifiers: [
      'org.idpf.epub-container',
      'public.xml',
      'public.zip-archive',
    ],
  );

  @override
  Future<BookImportFile?> open() async {
    final file = await openFile(acceptedTypeGroups: const [_bookTypes]);
    if (file == null) return null;
    return BookImportFile(name: file.name, bytes: await file.readAsBytes());
  }
}
