import 'dart:convert';

import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';

enum BookReaderAnnotationExportFormat { markdown, json }

class BookReaderAnnotationExport {
  const BookReaderAnnotationExport({
    required this.content,
    required this.extension,
    required this.mimeType,
  });

  final String content;
  final String extension;
  final String mimeType;
}

abstract final class BookReaderAnnotationExporter {
  static BookReaderAnnotationExport create({
    required BookProject project,
    required BookReaderAnnotationExportFormat format,
    required String languageCode,
  }) => switch (format) {
    BookReaderAnnotationExportFormat.markdown => BookReaderAnnotationExport(
      content: _markdown(project, languageCode == 'en'),
      extension: 'md',
      mimeType: 'text/markdown',
    ),
    BookReaderAnnotationExportFormat.json => BookReaderAnnotationExport(
      content: const JsonEncoder.withIndent('  ').convert({
        'format': 'dnevnik-reader-annotations',
        'version': 1,
        'book': {
          'id': project.id,
          'title': project.metadata.title,
          'author': project.metadata.author,
          'languageCode': project.metadata.languageCode,
        },
        'sections': [
          for (final section in project.sections)
            {
              'id': section.id,
              'title': section.title,
              'type': section.type.name,
            },
        ],
        'annotations': project.readerAnnotations.toJson(),
      }),
      extension: 'json',
      mimeType: 'application/json',
    ),
  };

  static String _markdown(BookProject project, bool english) {
    final annotations = project.readerAnnotations;
    final buffer = StringBuffer()
      ..writeln(
        '# ${english ? 'Reader annotations' : 'Читательские аннотации'} — ${project.metadata.title}',
      );
    if (project.metadata.author.trim().isNotEmpty) {
      buffer.writeln(
        '${english ? 'Author' : 'Автор'}: ${project.metadata.author.trim()}',
      );
    }
    buffer.writeln();

    for (final section in project.sections) {
      final bookmarks = annotations.bookmarks
          .where((item) => item.sectionId == section.id)
          .toList();
      final highlights = annotations.highlights
          .where((item) => item.sectionId == section.id)
          .toList();
      final quotes = annotations.quotes
          .where((item) => item.sectionId == section.id)
          .toList();
      final notes = annotations.notes
          .where((item) => item.sectionId == section.id)
          .toList();
      if (bookmarks.isEmpty &&
          highlights.isEmpty &&
          quotes.isEmpty &&
          notes.isEmpty) {
        continue;
      }

      buffer
        ..writeln('## ${section.title}')
        ..writeln();
      if (highlights.isNotEmpty) {
        buffer
          ..writeln('### ${english ? 'Highlights' : 'Выделения'}')
          ..writeln();
        for (final item in highlights) {
          buffer.writeln(
            '- ${_colorMarker(item.color)} “${_singleLine(item.excerpt)}” (${_percent(item.sectionProgress)})',
          );
        }
        buffer.writeln();
      }
      if (quotes.isNotEmpty) {
        buffer
          ..writeln('### ${english ? 'Quotes' : 'Цитаты'}')
          ..writeln();
        for (final item in quotes) {
          buffer
            ..writeln('> ${_singleLine(item.text)}')
            ..writeln()
            ..writeln('*${_percent(item.sectionProgress)}*')
            ..writeln();
        }
      }
      if (notes.isNotEmpty) {
        buffer
          ..writeln('### ${english ? 'Notes' : 'Заметки'}')
          ..writeln();
        for (final item in notes) {
          buffer
            ..writeln('- **${_singleLine(item.text)}**')
            ..writeln('  - “${_singleLine(item.excerpt)}”')
            ..writeln('  - ${_percent(item.sectionProgress)}');
        }
        buffer.writeln();
      }
      if (bookmarks.isNotEmpty) {
        buffer
          ..writeln('### ${english ? 'Bookmarks' : 'Закладки'}')
          ..writeln();
        for (final item in bookmarks) {
          buffer.writeln(
            '- ${_singleLine(item.excerpt)} (${_percent(item.sectionProgress)})',
          );
        }
        buffer.writeln();
      }
    }

    if (annotations.bookmarks.isEmpty &&
        annotations.highlights.isEmpty &&
        annotations.quotes.isEmpty &&
        annotations.notes.isEmpty) {
      buffer.writeln(
        english ? '_No annotations yet._' : '_Аннотаций пока нет._',
      );
    }
    return buffer.toString();
  }

  static String _percent(double value) => '${(value * 100).round()}%';

  static String _singleLine(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _colorMarker(BookReaderHighlightColor color) => switch (color) {
    BookReaderHighlightColor.yellow => '🟨',
    BookReaderHighlightColor.green => '🟩',
    BookReaderHighlightColor.blue => '🟦',
    BookReaderHighlightColor.pink => '🩷',
  };
}
