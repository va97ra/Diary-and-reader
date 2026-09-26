import 'dart:convert';
import 'dart:typed_data';

import 'package:dnevnik/features/books/data/book_project_backup_file_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a backup is read as UTF-8, so Russian titles survive', () {
    const archive = '{"title":"Сад у старой мельницы"}';
    final bytes = Uint8List.fromList(utf8.encode(archive));

    expect(decodeBackupBytes(bytes), archive);
    // What XFile.readAsString made of the same bytes on Android.
    expect(String.fromCharCodes(bytes), isNot(archive));
  });

  test('a byte order mark before the backup is dropped', () {
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode('{}')]);

    expect(decodeBackupBytes(bytes), '{}');
  });
}
