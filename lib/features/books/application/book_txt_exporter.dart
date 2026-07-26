import 'dart:convert';
import 'dart:typed_data';

import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/application/book_section_outline.dart';
import 'package:dnevnik/features/books/application/plain_text_rich_renderer.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';

abstract final class BookTxtExporter {
  static BookExportArtifact create(BookProject project) {
    final titleUnderline = List.filled(
      project.metadata.title.trim().length.clamp(3, 72),
      '=',
    ).join();
    final text = StringBuffer()
      ..writeln(project.metadata.title.trim())
      ..writeln(titleUnderline);
    if (project.metadata.subtitle.trim().isNotEmpty) {
      text.writeln(project.metadata.subtitle.trim());
    }
    if (project.metadata.author.trim().isNotEmpty) {
      text.writeln('\n${project.metadata.author.trim()}');
    }
    if (project.metadata.description.trim().isNotEmpty) {
      text.writeln('\n${project.metadata.description.trim()}');
    }
    for (final entry in BookSectionOutline.flatten(project.sections)) {
      final prefix = List.filled(entry.depth, '  ').join();
      final sectionUnderline = List.filled(
        entry.section.title.length.clamp(3, 72),
        '-',
      ).join();
      if (project.layoutSettings.showChapterTitlesInBody) {
        text
          ..writeln('\n$prefix${entry.section.title}')
          ..writeln('$prefix$sectionUnderline');
      } else {
        text.writeln();
      }
      text.writeln(PlainTextRichRenderer.render(entry.section.content));
    }
    return BookExportArtifact(
      bytes: Uint8List.fromList(
        utf8.encode('${text.toString().trimRight()}\n'),
      ),
      extension: 'txt',
      mimeType: 'text/plain; charset=utf-8',
    );
  }
}
