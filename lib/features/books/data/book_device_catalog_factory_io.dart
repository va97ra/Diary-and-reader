import 'dart:io';

import 'package:dnevnik/features/books/application/book_device_catalog.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/domain/book_scan_folder.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

BookDeviceCatalogGateway createBookDeviceCatalog() =>
    IoBookDeviceCatalogGateway();

class IoBookDeviceCatalogGateway
    implements BookDeviceCatalogGateway, BookDownloadsCatalogGateway {
  static const _channel = MethodChannel('literia/book_files');

  @override
  bool get supportsFolderScanning => true;

  @override
  Future<bool> hasDownloadsAccess() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod<bool>('hasDownloadsAccess') ?? false;
  }

  @override
  Future<bool> requestDownloadsAccess() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod<bool>('requestDownloadsAccess') ?? false;
  }

  @override
  Future<DeviceBookScanResult> scanDownloads() async {
    if (Platform.isAndroid) {
      final value = await _channel.invokeMapMethod<String, dynamic>(
        'scanDownloads',
      );
      return _scanResultFromMap(value);
    }
    final home =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    if (home == null || home.isEmpty) return const DeviceBookScanResult();
    return _scanDirectories([
      BookScanFolder(
        uri: '$home${Platform.pathSeparator}Downloads',
        name: 'Downloads',
      ),
    ]);
  }

  @override
  Future<BookScanFolder?> chooseFolder() async {
    if (Platform.isAndroid) {
      final value = await _channel.invokeMapMethod<String, dynamic>(
        'chooseFolder',
      );
      if (value == null) return null;
      final uri = value['uri']?.toString() ?? '';
      if (uri.isEmpty) return null;
      return BookScanFolder(
        uri: uri,
        name: value['name']?.toString() ?? 'Books',
      );
    }
    final path = await getDirectoryPath();
    if (path == null) return null;
    return BookScanFolder(uri: path, name: _lastSegment(path));
  }

  @override
  Future<DeviceBookScanResult> scan(List<BookScanFolder> folders) async {
    if (folders.isEmpty) return const DeviceBookScanResult();
    if (Platform.isAndroid) {
      final value = await _channel.invokeMapMethod<String, dynamic>(
        'scanFolders',
        {'uris': folders.map((folder) => folder.uri).toList()},
      );
      return _scanResultFromMap(value);
    }

    return _scanDirectories(folders);
  }

  Future<DeviceBookScanResult> _scanDirectories(
    List<BookScanFolder> folders,
  ) async {
    final books = <DeviceBookCandidate>[];
    final inaccessible = <String>[];
    for (final folder in folders) {
      final directory = Directory(folder.uri);
      if (!await directory.exists()) {
        inaccessible.add(folder.uri);
        continue;
      }
      try {
        await for (final entity in directory.list(recursive: true)) {
          if (entity is! File || !_isBookName(entity.path)) continue;
          final stat = await entity.stat();
          books.add(
            DeviceBookCandidate(
              uri: entity.path,
              name: _lastSegment(entity.path),
              folderName: folder.name,
              sizeBytes: stat.size,
              modifiedAt: stat.modified,
            ),
          );
        }
      } on FileSystemException {
        inaccessible.add(folder.uri);
      }
    }
    return DeviceBookScanResult(
      books: books,
      inaccessibleFolderUris: inaccessible,
    );
  }

  @override
  Future<BookImportFile> materialize(DeviceBookCandidate candidate) async {
    if (!Platform.isAndroid) {
      return BookImportFile(
        name: candidate.name,
        bytes: await File(candidate.uri).readAsBytes(),
        sourceUri: candidate.uri,
        sourceSizeBytes: candidate.sizeBytes,
        sourceModifiedMillis: candidate.modifiedAt?.millisecondsSinceEpoch ?? 0,
      );
    }
    final value = await _channel.invokeMapMethod<String, dynamic>(
      'materialize',
      {'uri': candidate.uri},
    );
    final path = value?['path']?.toString();
    if (path == null || path.isEmpty) {
      throw FileSystemException('The selected book could not be copied.');
    }
    final temporary = File(path);
    try {
      return BookImportFile(
        name: value?['name']?.toString() ?? candidate.name,
        bytes: await temporary.readAsBytes(),
        sourceUri: candidate.uri,
        sourceSizeBytes: candidate.sizeBytes,
        sourceModifiedMillis: candidate.modifiedAt?.millisecondsSinceEpoch ?? 0,
      );
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  @override
  Future<void> releaseFolder(BookScanFolder folder) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod<void>('releaseFolder', {'uri': folder.uri});
    }
  }

  @override
  Future<int?> availableBytes() async {
    if (!Platform.isAndroid) return null;
    return _channel.invokeMethod<int>('availableBytes');
  }

  DeviceBookCandidate? _candidateFromMap(Map<dynamic, dynamic> raw) {
    final uri = raw['uri']?.toString() ?? '';
    final name = raw['name']?.toString() ?? '';
    if (uri.isEmpty || name.isEmpty) return null;
    final modifiedMillis = raw['modified'] is num
        ? (raw['modified'] as num).toInt()
        : 0;
    return DeviceBookCandidate(
      uri: uri,
      name: name,
      folderName: raw['folderName']?.toString() ?? '',
      sizeBytes: raw['size'] is num ? (raw['size'] as num).toInt() : 0,
      modifiedAt: modifiedMillis > 0
          ? DateTime.fromMillisecondsSinceEpoch(modifiedMillis)
          : null,
    );
  }

  DeviceBookScanResult _scanResultFromMap(Map<String, dynamic>? value) {
    final books = (value?['books'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(_candidateFromMap)
        .whereType<DeviceBookCandidate>()
        .toList();
    final inaccessible =
        (value?['inaccessibleFolderUris'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();
    return DeviceBookScanResult(
      books: books,
      inaccessibleFolderUris: inaccessible,
    );
  }

  bool _isBookName(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.epub') ||
        lower.endsWith('.fb2') ||
        lower.endsWith('.zip') ||
        lower.endsWith('.txt') ||
        lower.endsWith('.rtf') ||
        lower.endsWith('.docx') ||
        lower.endsWith('.mobi') ||
        lower.endsWith('.doc') ||
        lower.endsWith('.chm');
  }

  String _lastSegment(String path) => path
      .replaceAll('\\', '/')
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .last;
}
