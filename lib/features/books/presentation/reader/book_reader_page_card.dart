import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_reader_text_anchor.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_document_view.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_layout_engine.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:flutter/material.dart';

class BookReaderPageCard extends StatelessWidget {
  const BookReaderPageCard({
    required this.width,
    required this.height,
    required this.pageNumber,
    required this.pageCount,
    required this.settings,
    required this.palette,
    required this.layout,
    required this.assets,
    required this.highlights,
    required this.selectionGeneration,
    required this.onSelectionChanged,
    required this.speechTargetMode,
    required this.showPageNumber,
    this.speechRange,
    this.onSpeechTargetSelected,
    super.key,
  });

  final double width;
  final double height;
  final int pageNumber;
  final int pageCount;
  final BookReaderSettings settings;
  final BookReaderPalette palette;
  final BookReaderPageLayout layout;
  final List<BookAsset> assets;
  final List<BookReaderRenderHighlight> highlights;
  final int selectionGeneration;
  final ValueChanged<TextSelection?> onSelectionChanged;
  final bool speechTargetMode;
  final bool showPageNumber;
  final BookReaderTextRange? speechRange;
  final ValueChanged<int>? onSpeechTargetSelected;

  @override
  Widget build(BuildContext context) {
    final metrics = BookReaderPageMetrics.resolve(
      width: width,
      height: height,
      settings: settings,
    );
    return Container(
      key: ValueKey('reader-page-$pageNumber'),
      width: width,
      height: height,
      padding: EdgeInsets.fromLTRB(
        metrics.horizontalPadding,
        metrics.topPadding,
        metrics.horizontalPadding,
        metrics.bottomPadding,
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRect(
              child: BookReaderDocumentView(
                fragments: layout.fragments,
                settings: settings,
                palette: palette,
                assets: assets,
                highlights: highlights,
                selectionGeneration: selectionGeneration,
                onSelectionChanged: onSelectionChanged,
                speechTargetMode: speechTargetMode,
                speechRange: speechRange,
                onSpeechTargetSelected: onSpeechTargetSelected,
                constrainToMeasuredHeight: true,
              ),
            ),
          ),
          SizedBox(
            height: metrics.footerHeight,
            child: !showPageNumber
                ? null
                : Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      AppStrings.of(
                        context,
                      ).readerPageOf(pageNumber, pageCount),
                      style: TextStyle(color: palette.mutedInk, fontSize: 11),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
