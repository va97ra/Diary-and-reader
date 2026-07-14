import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_formatting_toolbar.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_navigator.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_properties_panel.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_section_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class AuthorWorkspacePage extends StatefulWidget {
  const AuthorWorkspacePage({required this.controller, super.key});

  final AuthorWorkspaceController controller;

  @override
  State<AuthorWorkspacePage> createState() => _AuthorWorkspacePageState();
}

class _AuthorWorkspacePageState extends State<AuthorWorkspacePage> {
  QuillController? _editorController;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = widget.controller.activeProject!;
    final section = project.activeSection!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1500;
        final isTablet = constraints.maxWidth >= 700;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.metadata.title),
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: strings.language,
                onPressed: () => widget.controller.setLanguage(
                  widget.controller.languageCode == 'ru' ? 'en' : 'ru',
                ),
                icon: Text(widget.controller.languageCode.toUpperCase()),
              ),
              if (!isDesktop)
                IconButton(
                  tooltip: strings.properties,
                  onPressed: _showProperties,
                  icon: const Icon(Icons.tune),
                ),
            ],
          ),
          body: Row(
            children: [
              if (isTablet)
                SizedBox(
                  width: isDesktop ? 290 : 250,
                  child: BookNavigator(controller: widget.controller),
                ),
              Expanded(
                child: BookSectionEditor(
                  key: ValueKey(section.id),
                  section: section,
                  pageFormat: project.layoutSettings.pageFormat,
                  paragraphSettings: project.paragraphSettings,
                  showToolbar: isTablet,
                  saveState: widget.controller.saveState,
                  viewMode: project.layoutSettings.viewMode,
                  onViewModeChanged: (viewMode) =>
                      widget.controller.updateLayoutSettings(
                        project.layoutSettings.copyWith(viewMode: viewMode),
                      ),
                  onTitleChanged: widget.controller.updateSectionTitle,
                  onContentChanged: widget.controller.updateSectionContent,
                  onControllerReady: (controller) =>
                      _editorController = controller,
                ),
              ),
              if (isDesktop)
                SizedBox(
                  width: 300,
                  child: BookPropertiesPanel(controller: widget.controller),
                ),
            ],
          ),
          bottomNavigationBar: isTablet
              ? null
              : NavigationBar(
                  selectedIndex: 1,
                  onDestinationSelected: (index) {
                    if (index == 0) _showManuscript();
                    if (index == 2) _showFormatting();
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.account_tree_outlined),
                      label: strings.manuscript,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.edit_outlined),
                      label: strings.editor,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.text_format),
                      label: strings.formatting,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _showManuscript() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.82,
      child: BookNavigator(
        controller: widget.controller,
        closeAfterSelection: true,
      ),
    ),
  );

  Future<void> _showProperties() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.82,
      child: BookPropertiesPanel(controller: widget.controller),
    ),
  );

  Future<void> _showFormatting() async {
    final controller = _editorController;
    if (controller == null) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => BookFormattingSheet(
        controller: controller,
        paragraphSettings: widget.controller.activeProject!.paragraphSettings,
      ),
    );
  }
}
