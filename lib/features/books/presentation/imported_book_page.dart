import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_navigator.dart';
import 'package:flutter/material.dart';

class ImportedBookPage extends StatelessWidget {
  const ImportedBookPage({
    required this.controller,
    required this.onOpenReader,
    required this.onImportBook,
    super.key,
  });

  final AuthorWorkspaceController controller;
  final VoidCallback onOpenReader;
  final VoidCallback onImportBook;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = controller.activeProject!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showNavigator = constraints.maxWidth >= 700;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.metadata.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  strings.importedBook,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                key: const ValueKey('import-another-book'),
                tooltip: strings.importEbook,
                onPressed: onImportBook,
                icon: const Icon(Icons.upload_file_outlined),
              ),
              IconButton(
                key: const ValueKey('open-imported-book-reader'),
                tooltip: strings.openBook,
                onPressed: onOpenReader,
                icon: const Icon(Icons.chrome_reader_mode_outlined),
              ),
              IconButton(
                tooltip: strings.language,
                onPressed: () => controller.setLanguage(
                  controller.languageCode == 'ru' ? 'en' : 'ru',
                ),
                icon: Text(controller.languageCode.toUpperCase()),
              ),
            ],
          ),
          body: Row(
            children: [
              if (showNavigator)
                SizedBox(
                  width: constraints.maxWidth >= 1500 ? 290 : 250,
                  child: BookNavigator(
                    controller: controller,
                    onImportBook: onImportBook,
                    onOpenReader: onOpenReader,
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withValues(
                                        alpha: 0.16,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.auto_stories_outlined,
                                      size: 38,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          project.metadata.title,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineSmall,
                                        ),
                                        if (project.metadata.subtitle
                                            .trim()
                                            .isNotEmpty)
                                          Text(project.metadata.subtitle),
                                        if (project.metadata.author
                                            .trim()
                                            .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              project.metadata.author,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text(strings.importedBookHint),
                              if (project.metadata.description
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 18),
                                Text(project.metadata.description),
                              ],
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(label: Text(project.sourceFormat)),
                                  Chip(
                                    label: Text(
                                      strings.sectionsInBook(
                                        project.sections.length,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (project.sourceFileName.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    '${strings.sourceFile}: ${project.sourceFileName}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              const SizedBox(height: 28),
                              FilledButton.icon(
                                key: const ValueKey('read-imported-book'),
                                onPressed: onOpenReader,
                                icon: const Icon(
                                  Icons.chrome_reader_mode_outlined,
                                ),
                                label: Text(strings.openBook),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: showNavigator
              ? null
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: OutlinedButton.icon(
                      key: const ValueKey('open-imported-library'),
                      onPressed: () => _showLibrary(context),
                      icon: const Icon(Icons.library_books_outlined),
                      label: Text(strings.library),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _showLibrary(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.84,
      child: BookNavigator(
        controller: controller,
        closeAfterSelection: true,
        onImportBook: onImportBook,
        onOpenReader: onOpenReader,
      ),
    ),
  );
}
