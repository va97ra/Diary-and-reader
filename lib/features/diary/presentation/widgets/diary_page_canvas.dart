import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/diary/domain/page_margins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class DiaryPageCanvas extends StatelessWidget {
  const DiaryPageCanvas({
    required this.pageNumber,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
    required this.margins,
    required this.editorKey,
    required this.viewportKey,
    super.key,
  });

  static const _mmToPixels = 96 / 25.4;
  final int pageNumber;
  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
  final PageMargins margins;
  final GlobalKey<EditorState> editorKey;
  final GlobalKey viewportKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 794).clamp(0.5, 1.0);
        final padding = EdgeInsets.fromLTRB(
          margins.left * _mmToPixels * scale,
          margins.top * _mmToPixels * scale,
          margins.right * _mmToPixels * scale,
          margins.bottom * _mmToPixels * scale,
        );
        return Center(
          child: Container(
            width: 794,
            height: 1123,
            padding: padding,
            decoration: BoxDecoration(
              color: AppTheme.paper,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRect(
                    key: viewportKey,
                    child: DefaultTextStyle.merge(
                      style: const TextStyle(
                        color: AppTheme.ink,
                        fontSize: 17,
                        height: 1.65,
                      ),
                      child: QuillEditor(
                        controller: controller,
                        focusNode: focusNode,
                        scrollController: scrollController,
                        config: QuillEditorConfig(
                          editorKey: editorKey,
                          placeholder: AppStrings.of(context).startWriting,
                          padding: EdgeInsets.zero,
                          scrollable: false,
                          autoFocus: false,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${AppStrings.of(context).page} $pageNumber',
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
