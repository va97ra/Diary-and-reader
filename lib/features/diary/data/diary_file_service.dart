import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';

class DiaryFileService {
  const DiaryFileService();

  static const _archiveType = XTypeGroup(
    label: 'Diary JSON',
    extensions: ['json'],
    mimeTypes: ['application/json'],
    uniformTypeIdentifiers: ['public.json'],
  );

  Future<bool> saveArchive(String archive) async {
    final fileName =
        'dnevnik-${DateFormat('yyyy-MM-dd-HHmm').format(DateTime.now())}.json';
    final location = await getSaveLocation(suggestedName: fileName);
    if (location == null) return false;

    final bytes = Uint8List.fromList(utf8.encode(archive));
    final file = XFile.fromData(
      bytes,
      mimeType: 'application/json',
      name: fileName,
    );
    await file.saveTo(location.path);
    return true;
  }

  Future<String?> openArchive() async {
    final file = await openFile(acceptedTypeGroups: const [_archiveType]);
    if (file == null) return null;
    return file.readAsString();
  }
}
