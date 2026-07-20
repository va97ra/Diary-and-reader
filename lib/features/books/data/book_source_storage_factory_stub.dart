import 'package:dnevnik/features/books/application/book_source_storage.dart';

Future<BookSourceStorage> createBookSourceStorage() async =>
    const EphemeralBookSourceStorage();
