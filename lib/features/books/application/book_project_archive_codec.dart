import 'dart:convert';

import 'package:dnevnik/features/books/domain/book_project.dart';

abstract final class BookProjectArchiveCodec {
  static const format = 'dnevnik-book-project';
  static const currentVersion = 1;

  static String encode(BookProject project) =>
      const JsonEncoder.withIndent('  ').convert({
        'format': format,
        'version': currentVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'project': project.toJson(),
      });

  static BookProject decode(String encoded) {
    final archive = jsonDecode(encoded);
    if (archive is! Map || archive['format'] != format) {
      throw const FormatException('Unsupported book project archive.');
    }
    if (archive['version'] != currentVersion || archive['project'] is! Map) {
      throw const FormatException('Unsupported book project archive version.');
    }
    final project = BookProject.fromJson(
      Map<String, dynamic>.from(archive['project'] as Map),
    );
    if (project.sections.isEmpty) {
      throw const FormatException('The book project has no sections.');
    }
    return project;
  }
}
