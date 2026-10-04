import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

/// Where a bookmark stands in the shown text, in display offsets, and its
/// number in the book.
typedef BookReaderBookmarkMark = ({int offset, int number});

/// The ribbon of a bookmark on the page, with its number in the book, the
/// same number the list of bookmarks shows.
class BookReaderBookmarkFlag extends StatelessWidget {
  const BookReaderBookmarkFlag({required this.number, super.key});

  final int number;

  static const color = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${AppStrings.of(context).bookmark} $number',
    child: SizedBox(
      width: 22,
      height: 30,
      child: CustomPaint(
        painter: const _RibbonPainter(color),
        child: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Align(
            alignment: Alignment.topCenter,
            child: Text(
              '$number',
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The flags of [marks] in a row, for the bookmarks in one place.
class BookReaderBookmarkFlags extends StatelessWidget {
  const BookReaderBookmarkFlags({required this.numbers, super.key});

  final List<int> numbers;

  @override
  Widget build(BuildContext context) => Row(
    key: const ValueKey('reader-bookmark-flags'),
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (index, number) in numbers.indexed) ...[
        if (index > 0) const SizedBox(width: 2),
        BookReaderBookmarkFlag(number: number),
      ],
    ],
  );
}

/// A ribbon with a notch cut into its lower end.
class _RibbonPainter extends CustomPainter {
  const _RibbonPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - 7)
      ..lineTo(0, size.height)
      ..close();
    canvas
      ..drawShadow(path, Colors.black, 2, false)
      ..drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RibbonPainter oldDelegate) => color != oldDelegate.color;
}
