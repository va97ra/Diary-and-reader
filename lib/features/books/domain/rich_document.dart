import 'dart:convert';

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

/// Reads the payload of a [type] embed, stored either directly
/// (`{type: data}`) or wrapped by Quill as `{'custom': '{"type": data}'}`.
Object? richDocumentEmbedData(Map<dynamic, dynamic> insert, String type) {
  final direct = insert[type];
  if (direct != null) return direct;
  final custom = insert['custom'];
  if (custom is! String) return null;
  try {
    final decoded = jsonDecode(custom);
    return decoded is Map ? decoded[type] : null;
  } on FormatException {
    return null;
  }
}

bool richDocumentIsPageBreak(Map<dynamic, dynamic> insert) =>
    richDocumentEmbedData(insert, 'bookPageBreak') != null;

String richDocumentPlainText(RichDocument document) =>
    document.map((operation) => operation['insert']).whereType<String>().join();

bool richDocumentHasContent(RichDocument document) => document.any((operation) {
  final insert = operation['insert'];
  return insert is Map || (insert is String && insert.trim().isNotEmpty);
});

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
