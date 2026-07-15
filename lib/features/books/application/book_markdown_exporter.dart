import 'dart:convert';
import 'dart:typed_data';

import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/application/book_section_outline.dart';
import 'package:dnevnik/features/books/application/markdown_rich_text_renderer.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';

abstract final class BookMarkdownExporter {
  static BookExportArtifact create(BookProject project) {
    final text = StringBuffer()
      ..writeln('# ${_heading(project.metadata.title)}');
    if (project.metadata.subtitle.trim().isNotEmpty) {
      text.writeln('\n*${_inline(project.metadata.subtitle)}*');
    }
    if (project.metadata.author.trim().isNotEmpty) {
      text.writeln('\n**${_inline(project.metadata.author)}**');
    }
    if (project.metadata.description.trim().isNotEmpty) {
      text.writeln('\n${_inline(project.metadata.description)}');
    }
    for (final entry in BookSectionOutline.flatten(project.sections)) {
      final level = (entry.depth + 2).clamp(2, 6);
      final headingPrefix = List.filled(level, '#').join();
      text
        ..writeln('\n$headingPrefix ${_heading(entry.section.title)}\n')
        ..writeln(MarkdownRichTextRenderer.render(entry.section.content));
    }
    return BookExportArtifact(
      bytes: Uint8List.fromList(
        utf8.encode('${text.toString().trimRight()}\n'),
      ),
      extension: 'md',
      mimeType: 'text/markdown; charset=utf-8',
    );
  }

  static String _heading(String value) => value
      .trim()
      .replaceAll('\\', '\\\\')
      .replaceAll('#', '\\#')
      .replaceAll('\n', ' ');

  static String _inline(String value) => value
      .trim()
      .replaceAll('\\', '\\\\')
      .replaceAll('*', '\\*')
      .replaceAll('_', '\\_')
      .replaceAll('\n', ' ');
}
