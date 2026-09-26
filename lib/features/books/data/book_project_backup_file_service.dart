import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

abstract interface class BookProjectBackupFileGateway {
  Future<bool> save({required String archive, required String bookTitle});

  Future<String?> open();
}

class BookProjectBackupFileService implements BookProjectBackupFileGateway {
  const BookProjectBackupFileService();

  static const _androidChannel = MethodChannel('literia/book_files');
  static const _archiveType = XTypeGroup(
    label: 'Literia book project',
    extensions: ['json'],
    mimeTypes: ['application/json'],
    uniformTypeIdentifiers: ['public.json'],
  );

  @override
  Future<bool> save({
    required String archive,
    required String bookTitle,
  }) async {
    final timestamp = DateFormat('yyyy-MM-dd-HHmm').format(DateTime.now());
    final fileName = '${_safeName(bookTitle)}-$timestamp.dnevnik-book.json';
    final bytes = Uint8List.fromList(utf8.encode(archive));
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _androidChannel.invokeMethod<bool>('saveTextFile', {
            'fileName': fileName,
            'mimeType': 'application/json',
            'bytes': bytes,
          }) ??
          false;
    }
    final location = await getSaveLocation(suggestedName: fileName);
    if (location == null) return false;
    final file = XFile.fromData(
      bytes,
      mimeType: 'application/json',
      name: fileName,
    );
    await file.saveTo(location.path);
    return true;
  }

  @override
  Future<String?> open() async {
    final file = await openFile(acceptedTypeGroups: const [_archiveType]);
    if (file == null) return null;
    // XFile.readAsString ignores the encoding for a file it holds in memory,
    // as on Android, and would read a Russian backup as Latin-1.
    return decodeBackupBytes(await file.readAsBytes());
  }

  String _safeName(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '-')
        .replaceAll(RegExp(r'\s+'), '-');
    return normalized.isEmpty ? 'book' : normalized;
  }
}

/// A backup as the app writes it: UTF-8, maybe behind a byte order mark.
String decodeBackupBytes(Uint8List bytes) =>
    utf8.decode(bytes, allowMalformed: true).replaceFirst('\ufeff', '');
