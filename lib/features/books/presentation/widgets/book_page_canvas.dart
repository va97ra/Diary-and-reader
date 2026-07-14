import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/presentation/book_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookPageCanvas extends StatelessWidget {
  const BookPageCanvas({
    required this.pageNumber,
    required this.scale,
    required this.pageFormat,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.editorKey,
    required this.viewportKey,
    required this.titleController,
    required this.onTitleChanged,
    super.key,
  });

  final int pageNumber;
  final double scale;
  final BookPageFormat pageFormat;
  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final GlobalKey<EditorState> editorKey;
  final GlobalKey viewportKey;
  final TextEditingController titleController;
  final ValueChanged<String> onTitleChanged;

  bool get _isFirstPage => pageNumber == 1;

  @override
  Widget build(BuildContext context) {
    final page = MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(
        width: pageFormat.width,
        height: pageFormat.height,
        padding: EdgeInsets.fromLTRB(
          pageFormat.marginLeft,
          pageFormat.marginTop,
          pageFormat.marginRight,
          pageFormat.marginBottom / 2,
        ),
        decoration: BoxDecoration(
          color: AppTheme.paper,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            if (_isFirstPage) ...[
              TextField(
                controller: titleController,
                cursorColor: AppTheme.ink,
                onChanged: onTitleChanged,
                maxLines: 2,
                style: TextStyle(
                  color: AppTheme.ink,
                  fontFamily: 'Georgia',
                  fontSize: BookTypography.titleSize,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.of(context).newChapter,
                  hintStyle: const TextStyle(color: Colors.blueGrey),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: ClipRect(
                key: viewportKey,
                child: QuillEditor(
                  controller: controller,
                  focusNode: focusNode,
                  scrollController: scrollController,
                  config: QuillEditorConfig(
                    editorKey: editorKey,
                    placeholder: AppStrings.of(context).startWriting,
                    padding: EdgeInsets.zero,
                    customStyles: BookTypography.editorStyles,
                    textSelectionThemeData: BookTypography.selectionTheme,
                    scrollable: false,
                    autoFocus: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: Text(
                '${AppStrings.of(context).page} $pageNumber · '
                'A4 ${pageFormat.widthMm.toInt()}×'
                '${pageFormat.heightMm.toInt()} мм',
                style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );

    return SizedBox(
      key: ValueKey('book-page-$pageNumber'),
      width: pageFormat.width * scale,
      height: pageFormat.height * scale,
      child: Transform.scale(
        alignment: Alignment.topLeft,
        scale: scale,
        child: page,
      ),
    );
  }
}
