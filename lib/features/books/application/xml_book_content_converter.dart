import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:xml/xml.dart';

abstract final class XmlBookContentConverter {
  static RichDocument convert(Iterable<XmlNode> nodes) {
    final operations = <Map<String, dynamic>>[];
    for (final node in nodes) {
      _appendNode(node, operations);
    }
    return operations.isEmpty ? emptyRichDocument() : operations;
  }

  static void _appendNode(XmlNode node, List<Map<String, dynamic>> operations) {
    if (node is XmlText) {
      final text = _normalized(node.value);
      if (text.isNotEmpty) _appendParagraphText(text, operations);
      return;
    }
    if (node is! XmlElement) return;
    final tag = node.name.local.toLowerCase();
    switch (tag) {
      case 'p':
        _appendBlock(node, operations, const {});
      case 'subtitle':
        _appendBlock(node, operations, const {'header': 2});
      case 'h1':
        _appendBlock(node, operations, const {'header': 1});
      case 'h2':
        _appendBlock(node, operations, const {'header': 2});
      case 'h3' || 'h4' || 'h5' || 'h6':
        _appendBlock(node, operations, const {'header': 3});
      case 'blockquote':
        final paragraphs = _directReadableBlocks(node);
        if (paragraphs.isEmpty) {
          _appendBlock(node, operations, const {'blockquote': true});
        } else {
          for (final paragraph in paragraphs) {
            _appendBlock(paragraph, operations, const {'blockquote': true});
          }
        }
      case 'cite':
        final paragraphs = _directReadableBlocks(node);
        for (final paragraph in paragraphs) {
          _appendBlock(paragraph, operations, const {'blockquote': true});
        }
      case 'pre':
        _appendBlock(node, operations, const {'code-block': true}, raw: true);
      case 'li':
        final list = node.parentElement?.name.local.toLowerCase() == 'ol'
            ? 'ordered'
            : 'bullet';
        _appendBlock(node, operations, {'list': list});
      case 'empty-line' || 'hr':
        operations.add({
          'insert': '\n',
          'attributes': {'bookParagraphStyle': 'sceneBreak'},
        });
      case 'title':
        break;
      case 'script' || 'style' || 'template' || 'svg' || 'math':
        break;
      default:
        for (final child in node.children) {
          _appendNode(child, operations);
        }
    }
  }

  static List<XmlElement> _directReadableBlocks(XmlElement parent) => parent
      .childElements
      .where((element) => const {'p', 'subtitle'}.contains(element.name.local))
      .toList();

  static void _appendBlock(
    XmlElement element,
    List<Map<String, dynamic>> operations,
    Map<String, dynamic> blockAttributes, {
    bool raw = false,
  }) {
    final start = operations.length;
    _appendInline(element, const {}, operations, raw: raw);
    _trimBlockRuns(operations, start);
    if (operations.length == start) return;
    operations.add({
      'insert': '\n',
      if (blockAttributes.isNotEmpty) 'attributes': blockAttributes,
    });
  }

  static void _appendParagraphText(
    String text,
    List<Map<String, dynamic>> operations,
  ) {
    operations
      ..add({'insert': text})
      ..add({'insert': '\n'});
  }

  static void _appendInline(
    XmlNode node,
    Map<String, dynamic> inherited,
    List<Map<String, dynamic>> operations, {
    required bool raw,
  }) {
    if (node is XmlText) {
      final text = raw ? node.value : _normalized(node.value);
      if (text.isNotEmpty) {
        operations.add({
          'insert': text,
          if (inherited.isNotEmpty) 'attributes': inherited,
        });
      }
      return;
    }
    if (node is! XmlElement) return;
    final tag = node.name.local.toLowerCase();
    if (tag == 'br') {
      operations.add({'insert': '\n'});
      return;
    }
    final attributes = Map<String, dynamic>.from(inherited);
    switch (tag) {
      case 'strong' || 'b':
        attributes['bold'] = true;
      case 'emphasis' || 'em' || 'i':
        attributes['italic'] = true;
      case 'u':
        attributes['underline'] = true;
      case 'strikethrough' || 'strike' || 's' || 'del':
        attributes['strike'] = true;
      case 'code':
        attributes['code'] = true;
      case 'sup':
        attributes['script'] = 'super';
      case 'sub':
        attributes['script'] = 'sub';
      case 'a':
        final href = node.attributes
            .where((attribute) => attribute.name.local == 'href')
            .firstOrNull
            ?.value;
        if (href != null && href.trim().isNotEmpty) {
          final normalized = href.trim();
          final uri = Uri.tryParse(normalized);
          if (uri != null &&
              (uri.scheme.isEmpty ||
                  const {'http', 'https', 'mailto'}.contains(uri.scheme))) {
            attributes['link'] = normalized;
          }
        }
    }
    for (final child in node.children) {
      _appendInline(child, attributes, operations, raw: raw);
    }
  }

  static void _trimBlockRuns(List<Map<String, dynamic>> operations, int start) {
    if (operations.length == start) return;
    final first = operations[start];
    first['insert'] = first['insert'].toString().trimLeft();
    final last = operations.last;
    last['insert'] = last['insert'].toString().trimRight();
    operations.removeWhere((operation) => operation['insert'] == '');
  }

  static String _normalized(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ');
}
