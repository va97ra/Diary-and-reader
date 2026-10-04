import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/presentation/book_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converts paragraph measurements for the editor canvas', () {
    final settings = BookParagraphSettings.forPreset(
      BookParagraphPreset.classic,
    );

    final paragraph = BookTypography.editorStyles(settings).paragraph!;

    // The paragraph indent moves the first line only, not the paragraph.
    expect(paragraph.horizontalSpacing.left, 0);
    expect(paragraph.style.fontFamily, 'Georgia');
    expect(paragraph.style.height, 1.35);
    expect(paragraph.verticalSpacing.top, 0);
    expect(paragraph.verticalSpacing.bottom, 0);
  });

  test('justified, centred, indented and listed paragraphs keep spacing', () {
    const settings = BookParagraphSettings(
      spacingBeforePt: 6,
      spacingAfterPt: 9,
    );
    final styles = BookTypography.editorStyles(settings);
    final before = BookPageFormat.pointsToLogicalPixels(6);
    final after = BookPageFormat.pointsToLogicalPixels(9);

    for (final block in [
      styles.paragraph!,
      styles.align!,
      styles.indent!,
      styles.lists!,
    ]) {
      expect(block.verticalSpacing.top, before);
      expect(block.verticalSpacing.bottom, after);
      expect(block.lineSpacing.top, before);
      expect(block.lineSpacing.bottom, after);
      expect(block.horizontalSpacing.left, 0);
    }
    // Lists are drawn in the book's font, not Quill's.
    expect(styles.lists!.style.fontFamily, settings.fontFamily);
  });

  test(
    'only body text set to the left or justified indents its first line',
    () {
      bool indents(List<Attribute<dynamic>> attributes) =>
          BookTypography.indentsFirstLine({
            for (final attribute in attributes) attribute.key: attribute,
          });

      expect(indents(const []), isTrue);
      expect(indents(const [Attribute.justifyAlignment]), isTrue);
      expect(indents(const [Attribute.leftAlignment]), isTrue);
      expect(indents([Attribute.indentL1]), isTrue);
      expect(indents(const [Attribute.centerAlignment]), isFalse);
      expect(indents(const [Attribute.rightAlignment]), isFalse);
      expect(indents(const [Attribute.h1]), isFalse);
      expect(indents(const [Attribute.blockQuote]), isFalse);
      expect(indents(const [Attribute.ul]), isFalse);
    },
  );

  testWidgets('the paragraph indent moves only the first line', (tester) async {
    const settings = BookParagraphSettings(paragraphIndentMm: 10);
    final indent = BookPageFormat.millimetersToLogicalPixels(10);
    final text = List.filled(30, 'слово').join(' ');
    final controller = QuillController(
      document: Document.fromJson([
        {'insert': '$text\n$text'},
        {
          'insert': '\n',
          'attributes': {'align': 'justify'},
        },
        {'insert': 'Цитата'},
        {
          'insert': '\n',
          'attributes': {'blockquote': true},
        },
      ]),
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [FlutterQuillLocalizations.delegate],
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: QuillEditor.basic(
              controller: controller,
              config: QuillEditorConfig(
                customStyles: BookTypography.editorStyles(settings),
                textSpanBuilder: BookTypography.textSpanBuilder(settings),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The first letter of both body paragraphs, the justified one too,
    // stands after the indent; the quote's does not.
    final firstLetters = find.byWidgetPredicate(
      (widget) =>
          widget is Padding &&
          widget.padding == EdgeInsetsDirectional.only(start: indent),
    );
    expect(firstLetters, findsNWidgets(2));
    final editorLeft = tester.getTopLeft(find.byType(QuillEditor)).dx;
    for (final letter in firstLetters.evaluate()) {
      final box = letter.renderObject! as RenderBox;
      expect(box.localToGlobal(Offset.zero).dx, closeTo(editorLeft, 0.5));
    }
    // The rest of each paragraph starts at the margin.
    final paragraphs = find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText().startsWith('\uFFFC'),
    );
    expect(paragraphs, findsNWidgets(2));
    for (final paragraph in paragraphs.evaluate()) {
      final box = paragraph.renderObject! as RenderBox;
      expect(box.localToGlobal(Offset.zero).dx, closeTo(editorLeft, 0.5));
      expect(box.size.height, greaterThan(40));
    }
    // A caret after the first letter still points into the same text.
    expect(controller.document.toPlainText().startsWith('слово'), isTrue);
    expect(tester.takeException(), isNull);
  });
}
