import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';

enum BookImportFormat { epub, fb2, fb2Zip }

abstract interface class BookFormatParser {
  Set<BookImportFormat> get formats;

  BookProject parse(
    BookImportFile file,
    DateTime timestamp,
    BookImportFormat format,
  );
}
