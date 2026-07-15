class BookReaderTextSelection {
  const BookReaderTextSelection({
    required this.startOffset,
    required this.endOffset,
    required this.text,
    required this.sectionProgress,
  });

  final int startOffset;
  final int endOffset;
  final String text;
  final double sectionProgress;
}
