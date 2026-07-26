import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/data/book_export_file_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('literia/book_files');

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('uses the native Android document saver for exported books', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return true;
        });

    final saved = await const BookExportFileService().save(
      artifact: BookExportArtifact(
        bytes: Uint8List.fromList([1, 2, 3]),
        extension: 'epub',
        mimeType: 'application/epub+zip',
      ),
      bookTitle: 'Новая книга',
    );

    expect(saved, isTrue);
    expect(received?.method, 'saveTextFile');
    expect(received?.arguments, {
      'fileName': 'Новая-книга.epub',
      'mimeType': 'application/epub+zip',
      'bytes': Uint8List.fromList([1, 2, 3]),
    });
  });
}
