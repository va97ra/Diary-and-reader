import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

abstract interface class BookImportFileGateway {
  Future<BookImportFile?> open();
}

abstract interface class BookBatchImportFileGateway
    implements BookImportFileGateway {
  Future<List<BookImportFile>> openMany();
}

class BookImportFileService implements BookBatchImportFileGateway {
  const BookImportFileService();

  static const _bookExtensions = [
    'epub',
    'fb2',
    'zip',
    'txt',
    'rtf',
    'docx',
    'mobi',
    'doc',
    'chm',
  ];
  static const _bookMimeTypes = [
    'application/epub+zip',
    'application/x-fictionbook+xml',
    'application/xml',
    'text/xml',
    'application/zip',
    'application/x-zip-compressed',
    'text/plain',
    'application/rtf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/x-mobipocket-ebook',
    'application/msword',
    'application/vnd.ms-htmlhelp',
    // Android's Downloads provider often assigns this generic MIME type to
    // sideloaded FB2 files. The parser still validates the file contents.
    'application/octet-stream',
  ];
  static const _bookTypes = XTypeGroup(
    label: 'Electronic books',
    extensions: _bookExtensions,
    mimeTypes: _bookMimeTypes,
    uniformTypeIdentifiers: [
      'org.idpf.epub-container',
      'public.xml',
      'public.zip-archive',
    ],
  );
  static const _androidBookTypes = XTypeGroup(
    label: 'Electronic books',
    // Android's Storage Access Framework filters by MIME type and warns for
    // custom extensions such as FB2. The generic MIME fallback keeps those
    // files visible while the importer validates their names and signatures.
    mimeTypes: _bookMimeTypes,
  );

  List<XTypeGroup> get _acceptedTypes => [
    defaultTargetPlatform == TargetPlatform.android
        ? _androidBookTypes
        : _bookTypes,
  ];

  @override
  Future<BookImportFile?> open() async {
    final file = await openFile(acceptedTypeGroups: _acceptedTypes);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return BookImportFile(
      name: _normalizedName(file.name, bytes),
      bytes: bytes,
    );
  }

  @override
  Future<List<BookImportFile>> openMany() async {
    final files = await openFiles(
      acceptedTypeGroups: _acceptedTypes,
      initialDirectory: defaultTargetPlatform == TargetPlatform.android
          ? 'content://com.android.externalstorage.documents/document/primary%3ADownload'
          : null,
    );
    final result = <BookImportFile>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      result.add(
        BookImportFile(name: _normalizedName(file.name, bytes), bytes: bytes),
      );
    }
    return result;
  }

  String _normalizedName(String name, Uint8List bytes) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.epub') ||
        lower.endsWith('.fb2') ||
        lower.endsWith('.zip') ||
        lower.endsWith('.txt') ||
        lower.endsWith('.rtf') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.mobi') ||
        lower.endsWith('.doc') ||
        lower.endsWith('.chm')) {
      return name;
    }
    final base = name.contains('.')
        ? name.substring(0, name.lastIndexOf('.'))
        : name;
    final prefix = utf8.decode(bytes.take(8192).toList(), allowMalformed: true);
    if (prefix.contains('<FictionBook') || prefix.contains('<fictionbook')) {
      return '$base.fb2';
    }
    if (bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4b &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04) {
      try {
        final archive = ZipDecoder().decodeBytes(bytes, verify: false);
        final names = archive.files.map((item) => item.name.toLowerCase());
        if (names.any((item) => item.endsWith('.fb2'))) {
          return '$base.fb2.zip';
        }
        if (names.contains('meta-inf/container.xml')) return '$base.epub';
        if (names.contains('word/document.xml')) return '$base.docx';
      } on Object {
        return '$base.zip';
      }
      return '$base.zip';
    }
    return name;
  }
}
