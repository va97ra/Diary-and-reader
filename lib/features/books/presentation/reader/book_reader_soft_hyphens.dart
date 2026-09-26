import 'package:dnevnik/features/books/presentation/reader/book_reader_layout_engine.dart';
import 'package:flutter/widgets.dart';

const _softHyphen = '\u00ad';

/// The room left at the end of every line of hyphenated text, where a
/// hyphen hangs when a word breaks there, as a share of the font size.
const bookReaderHyphenReserve = 0.4;

/// A line of [painter] that ends by breaking a word at a soft hyphen.
typedef BookReaderHyphenBreak = ({LineMetrics line, int offset});

/// The lines of laid out [painter] that end at a soft hyphen. [offset] is
/// the index of that soft hyphen in [text], the painter's plain text.
List<BookReaderHyphenBreak> bookReaderHyphenBreaks(
  TextPainter painter,
  String text,
) {
  final breaks = <BookReaderHyphenBreak>[];
  final lines = painter.computeLineMetrics();
  // The last line ends the paragraph, never a broken word.
  for (final line in lines.take(lines.length - 1)) {
    final end = painter.getPositionForOffset(
      Offset(painter.width, line.baseline),
    );
    final lineEnd = painter.getLineBoundary(end).end;
    if (lineEnd > 0 &&
        lineEnd <= text.length &&
        text[lineEnd - 1] == _softHyphen) {
      breaks.add((line: line, offset: lineEnd - 1));
    }
  }
  return breaks;
}

/// Draws the hyphen where a line ends at a soft hyphen. Flutter breaks a
/// word there but, unlike a browser, leaves the hyphen out, so a hyphenated
/// book would read «счи / тали». [child] is the text of [span], laid out at
/// its width less [bookReaderCaretReserve].
class BookReaderSoftHyphens extends StatelessWidget {
  const BookReaderSoftHyphens({
    required this.span,
    required this.textAlign,
    required this.textDirection,
    required this.child,
    super.key,
  });

  final TextSpan span;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = span.toPlainText(includeSemanticsLabels: false);
    if (!text.contains(_softHyphen)) return child;
    return CustomPaint(
      foregroundPainter: _SoftHyphenPainter(
        span: span,
        text: text,
        textAlign: textAlign,
        textDirection: textDirection,
      ),
      child: child,
    );
  }
}

class _SoftHyphenPainter extends CustomPainter {
  _SoftHyphenPainter({
    required this.span,
    required this.text,
    required this.textAlign,
    required this.textDirection,
  });

  final TextSpan span;
  final String text;
  final TextAlign textAlign;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final painter =
        TextPainter(
          text: span,
          textAlign: textAlign,
          textDirection: textDirection,
          textScaler: TextScaler.noScaling,
        )..layout(
          maxWidth: (size.width - bookReaderCaretReserve).clamp(0, size.width),
        );
    for (final (:line, :offset) in bookReaderHyphenBreaks(painter, text)) {
      final hyphen = TextPainter(
        text: TextSpan(text: '-', style: _styleAt(offset)),
        textDirection: textDirection,
        textScaler: TextScaler.noScaling,
      )..layout();
      final baseline = hyphen.computeDistanceToActualBaseline(
        TextBaseline.alphabetic,
      );
      final x = textDirection == TextDirection.rtl
          ? line.left - hyphen.width
          : line.left + line.width;
      hyphen
        ..paint(canvas, Offset(x, line.baseline - baseline))
        ..dispose();
    }
    painter.dispose();
  }

  /// The style of the letters the hyphen follows, less any highlight.
  TextStyle? _styleAt(int softHyphen) {
    final position = TextPosition(offset: softHyphen > 0 ? softHyphen - 1 : 0);
    final inner = span.getSpanForPosition(position);
    final innerStyle = inner is TextSpan ? inner.style : null;
    final style = span.style?.merge(innerStyle) ?? innerStyle;
    if (style == null || style.background != null) return style;
    return style.copyWith(backgroundColor: const Color(0x00000000));
  }

  @override
  bool shouldRepaint(_SoftHyphenPainter oldDelegate) =>
      oldDelegate.span != span ||
      oldDelegate.textAlign != textAlign ||
      oldDelegate.textDirection != textDirection;
}
