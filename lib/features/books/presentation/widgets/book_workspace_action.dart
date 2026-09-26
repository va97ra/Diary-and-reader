/// The less frequent writer tools: the book's own tools first, then those
/// that keep the text safe.
enum BookWorkspaceAction {
  search,
  statistics,
  preview,
  export,
  history,
  trash,
  backup,
  restore;

  /// Whether this tool keeps the text safe rather than works on the book.
  bool get keepsTextSafe => index >= history.index;
}
