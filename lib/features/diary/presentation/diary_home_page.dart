import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/diary/application/diary_controller.dart';
import 'package:dnevnik/features/diary/presentation/widgets/diary_data_menu.dart';
import 'package:dnevnik/features/diary/presentation/widgets/diary_editor.dart';
import 'package:dnevnik/features/diary/presentation/widgets/entries_panel.dart';
import 'package:dnevnik/features/diary/presentation/widgets/formatting_toolbar.dart';
import 'package:dnevnik/features/diary/presentation/widgets/margins_sheet.dart';
import 'package:flutter/material.dart';

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({required this.controller, super.key});

  final DiaryController controller;

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  final _editorKey = GlobalKey<DiaryEditorState>();
  late final TextEditingController _titleController;
  String? _editingEntryId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final entry = widget.controller.activeEntry!;
    _syncTitle(entry.id, entry.title);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: TextField(
              key: ValueKey(widget.controller.languageCode),
              controller: _titleController,
              decoration: InputDecoration(hintText: strings.newEntryTitle),
              style: Theme.of(context).textTheme.titleLarge,
              onChanged: (title) =>
                  widget.controller.updateTitle(entry.id, title),
            ),
            actions: [
              IconButton(
                tooltip: strings.language,
                onPressed: () => widget.controller.setLanguage(
                  widget.controller.languageCode == 'ru' ? 'en' : 'ru',
                ),
                icon: Text(widget.controller.languageCode.toUpperCase()),
              ),
              IconButton(
                tooltip: strings.margins,
                onPressed: _showMargins,
                icon: const Icon(Icons.fit_screen_outlined),
              ),
              IconButton(
                tooltip: strings.newEntry,
                onPressed: () => widget.controller.addEntry(strings.newEntry),
                icon: const Icon(Icons.note_add_outlined),
              ),
              DiaryDataMenu(controller: widget.controller),
            ],
          ),
          body: Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: 300,
                  child: EntriesPanel(controller: widget.controller),
                ),
              Expanded(
                child: DiaryEditor(
                  key: _editorKey,
                  entry: entry,
                  margins: widget.controller.margins,
                  showToolbar: isDesktop,
                  onPageChanged: (index, document) =>
                      widget.controller.updatePage(entry.id, index, document),
                  onPageOverflow: (index, splitOffset) => widget.controller
                      .paginatePage(entry.id, index, splitOffset),
                  onAddPage: () => widget.controller.addPage(entry.id),
                ),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
                  selectedIndex: 1,
                  onDestinationSelected: (index) {
                    if (index == 0) _showEntries();
                    if (index == 1) {
                      widget.controller.addEntry(strings.newEntry);
                    }
                    if (index == 2) _showFormatting();
                  },
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.grid_view_outlined),
                      label: strings.entries,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.note_add_outlined),
                      label: strings.newEntry,
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

  void _syncTitle(String id, String title) {
    if (_editingEntryId == id) return;
    _editingEntryId = id;
    _titleController.value = TextEditingValue(
      text: title,
      selection: TextSelection.collapsed(offset: title.length),
    );
  }

  Future<void> _showEntries() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.78,
      child: EntriesPanel(
        controller: widget.controller,
        closeAfterSelection: true,
      ),
    ),
  );

  Future<void> _showFormatting() async {
    final controller = _editorKey.currentState?.activeController;
    if (controller == null) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => FormattingSheet(controller: controller),
    );
  }

  Future<void> _showMargins() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => MarginsSheet(
      initialValue: widget.controller.margins,
      onApply: widget.controller.setMargins,
    ),
  );

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
