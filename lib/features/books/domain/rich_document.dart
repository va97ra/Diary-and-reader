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

/// Removes the line height that older builds wrote into every paragraph.
/// Explicit values other than the former 1.5 default remain untouched.
RichDocument withoutLegacyDefaultLineHeight(RichDocument document) =>
    document.map((operation) {
      final copy = Map<String, dynamic>.from(operation);
      final rawAttributes = copy['attributes'];
      if (rawAttributes is! Map) return copy;
      final attributes = Map<String, dynamic>.from(rawAttributes);
      final lineHeight = attributes['line-height']?.toString();
      if (lineHeight != '1.5') return copy;
      attributes.remove('line-height');
      if (attributes.isEmpty) {
        copy.remove('attributes');
      } else {
        copy['attributes'] = attributes;
      }
      return copy;
    }).toList();
