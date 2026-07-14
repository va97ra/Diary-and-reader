import 'dart:convert';

import 'package:dnevnik/features/diary/domain/diary_snapshot.dart';

abstract final class DiaryArchiveCodec {
  static const currentVersion = 1;

  static String encode(DiarySnapshot snapshot) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'dnevnik-archive',
      'version': currentVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'data': snapshot.toJson(),
    });
  }

  static DiarySnapshot decode(String encoded) {
    final archive = jsonDecode(encoded);
    if (archive is! Map || archive['format'] != 'dnevnik-archive') {
      throw const FormatException('Unsupported diary archive.');
    }
    if (archive['version'] != currentVersion || archive['data'] is! Map) {
      throw const FormatException('Unsupported diary archive version.');
    }
    return DiarySnapshot.fromJson(
      Map<String, dynamic>.from(archive['data'] as Map),
    );
  }
}
