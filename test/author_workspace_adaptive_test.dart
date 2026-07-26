import 'dart:convert';
import 'dart:io';

import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/application/book_export_artifact.dart';
import 'package:dnevnik/features/books/application/book_image_file.dart';
import 'package:dnevnik/features/books/application/book_import_file.dart';
import 'package:dnevnik/features/books/application/book_pdf_font_assets.dart';
import 'package:dnevnik/features/books/application/book_project_archive_codec.dart';
import 'package:dnevnik/features/books/data/book_export_file_service.dart';
import 'package:dnevnik/features/books/data/book_import_file_service.dart';
import 'package:dnevnik/features/books/data/book_project_backup_file_service.dart';
import 'package:dnevnik/features/books/domain/book_image_placement.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/literia_test_navigation.dart';
import 'support/memory_author_workspace_repository.dart';

part 'author_workspace_adaptive_layout_scenarios.dart';
part 'author_workspace_adaptive_workflow_scenarios.dart';

void main() {
  registerAdaptiveLayoutScenarios();
  registerAdaptiveWorkflowScenarios();
}

Future<void> _openExportSheet(WidgetTester tester) async {
  final directExport = find.byKey(const ValueKey('writer-panel-export'));
  if (directExport.evaluate().isEmpty) {
    await tester.tap(find.byKey(const ValueKey('writer-more-menu')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const ValueKey('writer-panel-export')));
  await tester.pumpAndSettle();
}

class _MemoryBookExportSaver implements BookExportFileSaver {
  BookExportArtifact? artifact;
  String? bookTitle;

  @override
  Future<bool> save({
    required BookExportArtifact artifact,
    required String bookTitle,
  }) async {
    this.artifact = artifact;
    this.bookTitle = bookTitle;
    return true;
  }
}

class _MemoryBookImageGateway implements BookImageFileGateway {
  _MemoryBookImageGateway(this.file);

  final BookImageFile? file;
  int openCount = 0;

  @override
  Future<BookImageFile?> open() async {
    openCount++;
    return file;
  }
}

class _MemoryBookImportGateway implements BookImportFileGateway {
  _MemoryBookImportGateway(this.file);

  final BookImportFile? file;
  int openCount = 0;

  @override
  Future<BookImportFile?> open() async {
    openCount++;
    return file;
  }
}

class _FailingPdfFontLoader implements BookPdfFontLoader {
  @override
  Future<BookPdfFontAssets> load() =>
      Future.error(const FormatException('Font test failure'));
}

class _MemoryProjectBackupGateway implements BookProjectBackupFileGateway {
  String? savedArchive;
  String? archiveToOpen;

  @override
  Future<String?> open() async => archiveToOpen;

  @override
  Future<bool> save({
    required String archive,
    required String bookTitle,
  }) async {
    savedArchive = archive;
    return true;
  }
}
