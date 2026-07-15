import 'dart:io';

import 'package:dnevnik/features/books/data/file_book_version_repository.dart';
import 'package:dnevnik/features/books/domain/book_version_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<BookVersionRepository> createBookVersionRepository(
  SharedPreferences preferences,
) async {
  final supportDirectory = await getApplicationSupportDirectory();
  return FileBookVersionRepository(
    directory: Directory(
      '${supportDirectory.path}${Platform.pathSeparator}workspace'
      '${Platform.pathSeparator}versions',
    ),
  );
}
