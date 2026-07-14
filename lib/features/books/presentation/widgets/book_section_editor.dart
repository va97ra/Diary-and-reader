import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_formatting_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookSectionEditor extends StatefulWidget {
  const BookSectionEditor({
    required this.section,
    required this.onTitleChanged,
    required this.onContentChanged,
    required this.showToolbar,
    this.onControllerReady,
    super.key,
  });

  final BookSection section;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<RichDocument> onContentChanged;
  final bool showToolbar;
  final ValueChanged<QuillController>? onControllerReady;

  @override
  State<BookSectionEditor> createState() => BookSectionEditorState();
}

class BookSectionEditorState extends State<BookSectionEditor> {
  late final QuillController _controller;
  late final TextEditingController _titleController;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  QuillController get controller => _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuillController(
      document: Document.fromJson(widget.section.content),
      selection: const TextSelection.collapsed(offset: 0),
    )..addListener(_handleDocumentChanged);
    widget.onControllerReady?.call(_controller);
    _titleController = TextEditingController(text: widget.section.title);
  }

  void _handleDocumentChanged() {
    widget.onContentChanged(
      _controller.document.toDelta().toJson().cast<Map<String, dynamic>>(),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (widget.showToolbar) BookFormattingToolbar(controller: _controller),
      Expanded(
        child: ColoredBox(
          color: const Color(0xFF141824),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Container(
                margin: EdgeInsets.all(widget.showToolbar ? 24 : 8),
                padding: EdgeInsets.fromLTRB(
                  widget.showToolbar ? 72 : 22,
                  widget.showToolbar ? 56 : 24,
                  widget.showToolbar ? 72 : 22,
                  32,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.paper,
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      onChanged: widget.onTitleChanged,
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontFamily: 'Georgia',
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: AppStrings.of(context).newChapter,
                        hintStyle: const TextStyle(color: Colors.blueGrey),
                      ),
                    ),
                    const Divider(color: Color(0xFFE2E8F0), height: 32),
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontFamily: 'Georgia',
                          fontSize: 18,
                          height: 1.7,
                        ),
                        child: QuillEditor(
                          controller: _controller,
                          focusNode: _focusNode,
                          scrollController: _scrollController,
                          config: QuillEditorConfig(
                            placeholder: AppStrings.of(context).startWriting,
                            padding: EdgeInsets.zero,
                            scrollable: true,
                            autoFocus: false,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _controller
      ..removeListener(_handleDocumentChanged)
      ..dispose();
    _titleController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
