import 'package:dnevnik/features/books/application/book_source_storage.dart';
import 'package:dnevnik/features/books/data/file_book_source_storage.dart';
import 'package:path_provider/path_provider.dart';

Future<BookSourceStorage> createBookSourceStorage() async =>
    FileBookSourceStorage(
      supportDirectory: await getApplicationSupportDirectory(),
    );
