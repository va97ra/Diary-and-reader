import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/diary/domain/diary_entry.dart';
import 'package:dnevnik/features/diary/domain/page_margins.dart';
import 'package:dnevnik/features/diary/presentation/widgets/diary_page_canvas.dart';
import 'package:dnevnik/features/diary/presentation/widgets/formatting_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class DiaryEditor extends StatefulWidget {
  const DiaryEditor({
    required this.entry,
    required this.margins,
    required this.onPageChanged,
    required this.onAddPage,
    required this.onPageOverflow,
    required this.showToolbar,
    super.key,
  });

  final DiaryEntry entry;
  final PageMargins margins;
  final void Function(int pageIndex, PageDocument document) onPageChanged;
  final VoidCallback onAddPage;
  final void Function(int pageIndex, int splitOffset) onPageOverflow;
  final bool showToolbar;

  @override
  State<DiaryEditor> createState() => DiaryEditorState();
}

class DiaryEditorState extends State<DiaryEditor> {
  final List<QuillController> _controllers = [];
  final List<FocusNode> _focusNodes = [];
  final List<ScrollController> _scrollControllers = [];
  final List<GlobalKey<EditorState>> _editorKeys = [];
  final List<GlobalKey> _viewportKeys = [];
  int _activePage = 0;
  bool _paginationInProgress = false;

  QuillController get activeController => _controllers[_activePage];

  @override
  void initState() {
    super.initState();
    _createControllers();
  }

  @override
  void didUpdateWidget(covariant DiaryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final entryChanged = oldWidget.entry.id != widget.entry.id;
    final pagesChanged = !identical(oldWidget.entry.pages, widget.entry.pages);
    if (!entryChanged && !pagesChanged) return;

    final selectLast =
        !entryChanged &&
        widget.entry.pages.length > oldWidget.entry.pages.length;
    _disposeControllers();
    _createControllers();
    _activePage = selectLast ? _controllers.length - 1 : 0;
    _paginationInProgress = false;
    _schedulePaginationCheck();
  }

  void _createControllers() {
    for (var index = 0; index < widget.entry.pages.length; index++) {
      final controller = QuillController(
        document: Document.fromJson(widget.entry.pages[index]),
        selection: const TextSelection.collapsed(offset: 0),
      );
      controller.addListener(() => _savePage(index));
      _controllers.add(controller);
      _focusNodes.add(FocusNode()..addListener(() => _activatePage(index)));
      _scrollControllers.add(ScrollController());
      _editorKeys.add(GlobalKey<EditorState>());
      _viewportKeys.add(GlobalKey());
    }
    _schedulePaginationCheck();
  }

  void _activatePage(int index) {
    if (_focusNodes[index].hasFocus && _activePage != index && mounted) {
      setState(() => _activePage = index);
    }
  }

  void _savePage(int index) {
    final json = _controllers[index].document
        .toDelta()
        .toJson()
        .map((operation) => Map<String, dynamic>.from(operation))
        .toList();
    widget.onPageChanged(index, json);
    _schedulePaginationCheck(pageIndex: index);
  }

  void _schedulePaginationCheck({int? pageIndex}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _paginationInProgress) return;
      if (pageIndex != null) {
        _checkPageOverflow(pageIndex);
        return;
      }
      for (var index = 0; index < _controllers.length; index++) {
        if (_checkPageOverflow(index)) break;
      }
    });
  }

  bool _checkPageOverflow(int index) {
    if (index >= _controllers.length) return false;
    final editorState = _editorKeys[index].currentState;
    final viewportContext = _viewportKeys[index].currentContext;
    final viewport = viewportContext?.findRenderObject();
    if (editorState == null || viewport is! RenderBox || !viewport.hasSize) {
      return false;
    }
    final probe = viewport.localToGlobal(
      Offset(viewport.size.width - 8, viewport.size.height - 28),
    );
    final splitOffset = editorState.renderEditor
        .getPositionForOffset(probe)
        .offset;
    final lastContentOffset = _controllers[index].document.length - 1;
    if (splitOffset <= 0 || splitOffset >= lastContentOffset) return false;

    _paginationInProgress = true;
    widget.onPageOverflow(index, splitOffset);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showToolbar)
          DiaryFormattingToolbar(controller: activeController),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
            itemCount: _controllers.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              if (index == _controllers.length) {
                return Center(
                  child: OutlinedButton.icon(
                    onPressed: widget.onAddPage,
                    icon: const Icon(Icons.note_add_outlined),
                    label: Text(AppStrings.of(context).addPage),
                  ),
                );
              }
              return DiaryPageCanvas(
                pageNumber: index + 1,
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                scrollController: _scrollControllers[index],
                margins: widget.margins,
                editorKey: _editorKeys[index],
                viewportKey: _viewportKeys[index],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
    _scrollControllers.clear();
    _editorKeys.clear();
    _viewportKeys.clear();
  }
}
