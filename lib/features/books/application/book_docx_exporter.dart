import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dnevnik/features/books/application/book_docx_content_renderer.dart';
import 'package:dnevnik/features/books/application/book_docx_package_parts.dart';
import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';

abstract final class BookDocxExporter {
  static const mimeType =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

  static BookExportArtifact create(BookProject project) {
    final content = BookDocxContentRenderer.render(project);
    final archive = Archive()
      ..add(
        ArchiveFile.string(
          '[Content_Types].xml',
          BookDocxPackageParts.contentTypes,
        ),
      )
      ..add(
        ArchiveFile.string(
          '_rels/.rels',
          BookDocxPackageParts.packageRelationships,
        ),
      )
      ..add(
        ArchiveFile.string(
          'docProps/core.xml',
          BookDocxPackageParts.coreProperties(project),
        ),
      )
      ..add(
        ArchiveFile.string(
          'docProps/app.xml',
          BookDocxPackageParts.appProperties,
        ),
      )
      ..add(ArchiveFile.string('word/document.xml', content.documentXml))
      ..add(
        ArchiveFile.string(
          'word/_rels/document.xml.rels',
          BookDocxPackageParts.documentRelationships(
            content.relationships,
            content.images.map((image) => image.relationship).toList(),
          ),
        ),
      )
      ..add(
        ArchiveFile.string(
          'word/styles.xml',
          BookDocxPackageParts.styles(project),
        ),
      )
      ..add(
        ArchiveFile.string(
          'word/numbering.xml',
          BookDocxPackageParts.numbering(
            content.decimalNumberingIds,
            content.bulletNumberingIds,
          ),
        ),
      )
      ..add(
        ArchiveFile.string('word/settings.xml', BookDocxPackageParts.settings),
      )
      ..add(
        ArchiveFile.string(
          'word/fontTable.xml',
          BookDocxPackageParts.fontTable(project),
        ),
      )
      ..add(
        ArchiveFile.string(
          'word/header1.xml',
          BookDocxPackageParts.header(project),
        ),
      )
      ..add(
        ArchiveFile.string('word/footer1.xml', BookDocxPackageParts.footer),
      );
    for (final image in content.images) {
      archive.add(
        ArchiveFile(
          'word/${image.relationship.target}',
          image.asset.bytes.length,
          image.asset.bytes,
        ),
      );
    }

    return BookExportArtifact(
      bytes: Uint8List.fromList(
        ZipEncoder().encodeBytes(archive, modified: project.updatedAt.toUtc()),
      ),
      extension: 'docx',
      mimeType: mimeType,
    );
  }
}
