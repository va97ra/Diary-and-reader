typedef RichDocument = List<Map<String, dynamic>>;

RichDocument emptyRichDocument() => [
  <String, dynamic>{'insert': '\n'},
];

RichDocument richDocumentFromJson(Object? value) {
  if (value is! List) return emptyRichDocument();
  final operations = value
      .whereType<Map>()
      .map((operation) => Map<String, dynamic>.from(operation))
      .toList();
  return operations.isEmpty ? emptyRichDocument() : operations;
}

RichDocument mergeRichDocuments(Iterable<RichDocument> documents) {
  final merged = <Map<String, dynamic>>[];
  for (final document in documents) {
    merged.addAll(document.map(Map<String, dynamic>.from));
  }
  return merged.isEmpty ? emptyRichDocument() : merged;
}
