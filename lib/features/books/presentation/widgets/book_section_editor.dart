import 'package:dnevnik/features/books/application/book_page_paginator.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_formatting_toolbar.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_mobile_editor.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_page_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookSectionEditor extends StatefulWidget {
  const BookSectionEditor({
    required this.section,
    required this.pageFormat,
    required this.onTitleChanged,
    required this.onContentChanged,
    required this.showToolbar,
    this.onControllerReady,
    super.key,
  });

  final BookSection section;
  final BookPageFormat pageFormat;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<RichDocument> onContentChanged;
  final bool showToolbar;
  final ValueChanged<QuillController>? onControllerReady;

  @override
  State<BookSectionEditor> createState() => BookSectionEditorState();
}

class BookSectionEditorState extends State<BookSectionEditor> {
  final _controllers = <QuillController>[];
  final _focusNodes = <FocusNode>[];
  final _scrollControllers = <ScrollController>[];
  final _editorKeys = <GlobalKey<EditorState>>[];
  final _viewportKeys = <GlobalKey>[];
  late final TextEditingController _titleController;

  int _activePage = 0;
  bool _paginationInProgress = false;
  bool _usesPagedLayout = false;
  int _paginationLayoutRetries = 0;

  QuillController get controller => _controllers[_activePage];
  int get pageCount => _controllers.length;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section.title);
    _createPageControllers([widget.section.content]);
    widget.onControllerReady?.call(controller);
  }

  @override
  void didUpdateWidget(covariant BookSectionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageFormat == widget.pageFormat) return;
    final manuscript = BookPagePaginator.merge(_pageDocuments);
    _paginationInProgress = true;
    _disposePageControllers();
    _createPageControllers([manuscript]);
    _activePage = 0;
    _paginationInProgress = false;
    widget.onControllerReady?.call(controller);
    _schedulePagination();
  }

  void _createPageControllers(List<RichDocument> documents) {
    for (final document in documents) {
      final controller = QuillController(
        document: Document.fromJson(document),
        selection: const TextSelection.collapsed(offset: 0),
      );
      _applyDefaultLineHeight(controller, document);
      controller.addListener(() => _handleDocumentChanged(controller));
      _controllers.add(controller);

      final focusNode = FocusNode();
      focusNode.addListener(() => _activatePage(focusNode));
      _focusNodes.add(focusNode);
      _scrollControllers.add(ScrollController());
      _editorKeys.add(GlobalKey<EditorState>());
      _viewportKeys.add(GlobalKey());
    }
  }

  void _applyDefaultLineHeight(
    QuillController controller,
    RichDocument document,
  ) {
    var operationOffset = 0;
    for (final operation in document) {
      final insert = operation['insert'];
      final attributes = operation['attributes'];
      final hasLineHeight =
          attributes is Map && attributes.containsKey('line-height');
      if (insert is String && !hasLineHeight) {
        for (var index = 0; index < insert.length; index++) {
          if (insert[index] == '\n') {
            controller.formatText(
              operationOffset + index,
              1,
              LineHeightAttribute.lineHeightOneAndHalf,
            );
          }
        }
      }
      operationOffset += insert is String ? insert.length : 1;
    }
  }

  void _handleDocumentChanged(QuillController changedController) {
    final index = _controllers.indexOf(changedController);
    if (index < 0) return;
    widget.onContentChanged(BookPagePaginator.merge(_pageDocuments));
    if (_usesPagedLayout) _schedulePagination(pageIndex: index);
  }

  void _activatePage(FocusNode changedNode) {
    final index = _focusNodes.indexOf(changedNode);
    if (index < 0 || !changedNode.hasFocus || index == _activePage) return;
    setState(() => _activePage = index);
    widget.onControllerReady?.call(controller);
  }

  List<RichDocument> get _pageDocuments => _controllers
      .map(
        (controller) => controller.document
            .toDelta()
            .toJson()
            .map((operation) => Map<String, dynamic>.from(operation))
            .toList(),
      )
      .toList();

  void _schedulePagination({int? pageIndex}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_usesPagedLayout || _paginationInProgress) return;
      if (pageIndex != null) {
        final result = _checkPageOverflow(pageIndex);
        if (result == null) _retryPagination(pageIndex: pageIndex);
        return;
      }
      for (var index = 0; index < _controllers.length; index++) {
        final result = _checkPageOverflow(index);
        if (result == null) {
          _retryPagination();
          break;
        }
        if (result) break;
      }
    });
  }

  void _retryPagination({int? pageIndex}) {
    if (_paginationLayoutRetries >= 4) return;
    _paginationLayoutRetries++;
    _schedulePagination(pageIndex: pageIndex);
  }

  bool? _checkPageOverflow(int index) {
    if (index >= _controllers.length) return false;
    final editorState = _editorKeys[index].currentState;
    final viewportContext = _viewportKeys[index].currentContext;
    final viewport = viewportContext?.findRenderObject();
    if (editorState == null || viewport is! RenderBox || !viewport.hasSize) {
      return null;
    }
    _paginationLayoutRetries = 0;

    final probe = viewport.localToGlobal(
      Offset(viewport.size.width - 8, viewport.size.height - 24),
    );
    final splitOffset = editorState.renderEditor
        .getPositionForOffset(probe)
        .offset;
    final lastContentOffset = _controllers[index].document.length - 1;
    if (splitOffset <= 0 || splitOffset >= lastContentOffset) return false;

    final documents = _pageDocuments;
    final split = BookPagePaginator.split(documents[index], splitOffset);
    documents[index] = split.visible;
    final nextIndex = index + 1;
    if (nextIndex < documents.length) {
      documents[nextIndex] = BookPagePaginator.prependOverflow(
        split.overflow,
        documents[nextIndex],
      );
    } else {
      documents.add(split.overflow);
    }
    _replacePages(documents, nextIndex);
    return true;
  }

  void _replacePages(List<RichDocument> documents, int activePage) {
    _paginationInProgress = true;
    _disposePageControllers();
    _createPageControllers(documents);
    setState(() => _activePage = activePage.clamp(0, documents.length - 1));
    widget.onContentChanged(BookPagePaginator.merge(documents));
    widget.onControllerReady?.call(controller);
    _paginationInProgress = false;
    _schedulePagination();
  }

  void _selectMobilePage(int page) {
    if (page < 0 || page >= _controllers.length || page == _activePage) return;
    setState(() => _activePage = page);
    widget.onControllerReady?.call(controller);
  }

  @override
  Widget build(BuildContext context) {
    final pagedLayoutChanged = _usesPagedLayout != widget.showToolbar;
    _usesPagedLayout = widget.showToolbar;
    if (pagedLayoutChanged && _usesPagedLayout) _schedulePagination();

    return Column(
      children: [
        if (widget.showToolbar) BookFormattingToolbar(controller: controller),
        Expanded(
          child: widget.showToolbar
              ? _buildPagedEditor()
              : BookMobileEditor(
                  controller: controller,
                  focusNode: _focusNodes[_activePage],
                  scrollController: _scrollControllers[_activePage],
                  titleController: _titleController,
                  onTitleChanged: widget.onTitleChanged,
                  pageNumber: _activePage + 1,
                  pageCount: _controllers.length,
                  pageFormat: widget.pageFormat,
                  onPreviousPage: _activePage > 0
                      ? () => _selectMobilePage(_activePage - 1)
                      : null,
                  onNextPage: _activePage < _controllers.length - 1
                      ? () => _selectMobilePage(_activePage + 1)
                      : null,
                ),
        ),
      ],
    );
  }

  Widget _buildPagedEditor() => ColoredBox(
    color: const Color(0xFF141824),
    child: LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 32.0;
        final scale = widget.pageFormat.scaleForWidth(
          constraints.maxWidth - horizontalPadding * 2,
        );
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            96,
          ),
          itemCount: _controllers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 24),
          itemBuilder: (context, index) => Center(
            child: BookPageCanvas(
              pageNumber: index + 1,
              scale: scale,
              pageFormat: widget.pageFormat,
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              scrollController: _scrollControllers[index],
              editorKey: _editorKeys[index],
              viewportKey: _viewportKeys[index],
              titleController: _titleController,
              onTitleChanged: widget.onTitleChanged,
            ),
          ),
        );
      },
    ),
  );

  @override
  void dispose() {
    _disposePageControllers();
    _titleController.dispose();
    super.dispose();
  }

  void _disposePageControllers() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    for (final scrollController in _scrollControllers) {
      scrollController.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
    _scrollControllers.clear();
    _editorKeys.clear();
    _viewportKeys.clear();
  }
}
