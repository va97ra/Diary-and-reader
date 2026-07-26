import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/domain/book_scan_folder.dart';

class DeviceBookCandidate {
  const DeviceBookCandidate({
    required this.uri,
    required this.name,
    required this.folderName,
    required this.sizeBytes,
    this.modifiedAt,
  });

  final String uri;
  final String name;
  final String folderName;
  final int sizeBytes;
  final DateTime? modifiedAt;
}

class DeviceBookScanResult {
  const DeviceBookScanResult({
    this.books = const [],
    this.inaccessibleFolderUris = const [],
  });

  final List<DeviceBookCandidate> books;
  final List<String> inaccessibleFolderUris;
}

abstract interface class BookDeviceCatalogGateway {
  bool get supportsFolderScanning;

  Future<BookScanFolder?> chooseFolder();

  Future<DeviceBookScanResult> scan(List<BookScanFolder> folders);

  Future<BookImportFile> materialize(DeviceBookCandidate candidate);

  Future<void> releaseFolder(BookScanFolder folder);

  Future<int?> availableBytes();
}

abstract interface class BookDownloadsCatalogGateway {
  Future<bool> hasDownloadsAccess();

  Future<bool> requestDownloadsAccess();

  Future<DeviceBookScanResult> scanDownloads();
}

class UnsupportedBookDeviceCatalog implements BookDeviceCatalogGateway {
  const UnsupportedBookDeviceCatalog();

  @override
  bool get supportsFolderScanning => false;

  @override
  Future<int?> availableBytes() async => null;

  @override
  Future<BookScanFolder?> chooseFolder() async => null;

  @override
  Future<BookImportFile> materialize(DeviceBookCandidate candidate) =>
      throw UnsupportedError('Device book discovery is not supported.');

  @override
  Future<void> releaseFolder(BookScanFolder folder) async {}

  @override
  Future<DeviceBookScanResult> scan(List<BookScanFolder> folders) async =>
      const DeviceBookScanResult();
}
