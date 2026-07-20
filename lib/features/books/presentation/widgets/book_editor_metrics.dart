class BookEditorMetrics {
  const BookEditorMetrics({
    required this.words,
    required this.activePage,
    required this.pageCount,
  });

  final int words;
  final int activePage;
  final int pageCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookEditorMetrics &&
          words == other.words &&
          activePage == other.activePage &&
          pageCount == other.pageCount;

  @override
  int get hashCode => Object.hash(words, activePage, pageCount);
}
