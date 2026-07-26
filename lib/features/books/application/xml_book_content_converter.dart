import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:xml/xml.dart';

typedef BookImageResolver = String? Function(String source);

abstract final class XmlBookContentConverter {
  static RichDocument convert(
    Iterable<XmlNode> nodes, {
    BookImageResolver? imageResolver,
  }) {
    final operations = <Map<String, dynamic>>[];
    for (final node in nodes) {
      _appendNode(node, operations, imageResolver);
    }
    return operations.isEmpty ? emptyRichDocument() : operations;
  }

  static void _appendNode(
    XmlNode node,
    List<Map<String, dynamic>> operations,
    BookImageResolver? imageResolver,
  ) {
    if (node is XmlText) {
      final text = _normalized(node.value);
      if (text.isNotEmpty) _appendParagraphText(text, operations);
      return;
    }
    if (node is! XmlElement) return;
    final tag = node.name.local.toLowerCase();
    if (_isVerseContainer(node)) {
      _appendVerseBlock(node, operations, imageResolver);
      return;
    }
    switch (tag) {
      case 'p':
        _appendBlock(node, operations, const {}, imageResolver: imageResolver);
      case 'subtitle':
        _appendBlock(node, operations, const {
          'header': 2,
        }, imageResolver: imageResolver);
      case 'h1':
        _appendBlock(node, operations, const {
          'header': 1,
        }, imageResolver: imageResolver);
      case 'h2':
        _appendBlock(node, operations, const {
          'header': 2,
        }, imageResolver: imageResolver);
      case 'h3' || 'h4' || 'h5' || 'h6':
        _appendBlock(node, operations, const {
          'header': 3,
        }, imageResolver: imageResolver);
      case 'blockquote':
        final paragraphs = _directReadableBlocks(node);
        if (paragraphs.isEmpty) {
          _appendBlock(node, operations, const {
            'blockquote': true,
          }, imageResolver: imageResolver);
        } else {
          for (final paragraph in paragraphs) {
            _appendBlock(paragraph, operations, const {
              'blockquote': true,
            }, imageResolver: imageResolver);
          }
        }
      case 'cite':
        final paragraphs = _directReadableBlocks(node);
        for (final paragraph in paragraphs) {
          _appendBlock(paragraph, operations, const {
            'blockquote': true,
          }, imageResolver: imageResolver);
        }
      case 'pre':
        _appendBlock(
          node,
          operations,
          const {'code-block': true},
          raw: true,
          imageResolver: imageResolver,
        );
      case 'li':
        final list = node.parentElement?.name.local.toLowerCase() == 'ol'
            ? 'ordered'
            : 'bullet';
        _appendBlock(node, operations, {
          'list': list,
        }, imageResolver: imageResolver);
      case 'image' || 'img':
        _appendImage(node, operations, imageResolver, appendNewline: true);
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
          _appendNode(child, operations, imageResolver);
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
    BookImageResolver? imageResolver,
  }) {
    final start = operations.length;
    _appendInline(
      element,
      const {},
      operations,
      raw: raw,
      imageResolver: imageResolver,
    );
    _trimBlockRuns(operations, start);
    if (operations.length == start) return;
    operations.add({
      'insert': '\n',
      if (blockAttributes.isNotEmpty) 'attributes': blockAttributes,
    });
  }

  static void _appendVerseBlock(
    XmlElement element,
    List<Map<String, dynamic>> operations,
    BookImageResolver? imageResolver,
  ) {
    final start = operations.length;
    _appendInline(
      element,
      const {},
      operations,
      raw: false,
      imageResolver: imageResolver,
      softLineBreaks: true,
    );
    _trimBlockRuns(operations, start);
    if (operations.length == start) return;
    operations.add({'insert': '\n'});
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
    BookImageResolver? imageResolver,
    bool softLineBreaks = false,
  }) {
    if (node is XmlText) {
      final text = raw ? node.value : _normalized(node.value);
      if (softLineBreaks && text.trim().isEmpty) return;
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
    if (tag == 'image' || tag == 'img') {
      _appendImage(node, operations, imageResolver, appendNewline: false);
      return;
    }
    if (tag == 'br') {
      operations.add({'insert': softLineBreaks ? '\u2028' : '\n'});
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
      _appendInline(
        child,
        attributes,
        operations,
        raw: raw,
        imageResolver: imageResolver,
        softLineBreaks: softLineBreaks,
      );
    }
    if (softLineBreaks && tag == 'v') {
      operations.add({'insert': '\u2028'});
    } else if (softLineBreaks && tag == 'stanza') {
      operations.add({'insert': '\u2028'});
    }
  }

  static void _appendImage(
    XmlElement element,
    List<Map<String, dynamic>> operations,
    BookImageResolver? imageResolver, {
    required bool appendNewline,
  }) {
    if (imageResolver == null) return;
    final source = element.attributes
        .where((attribute) {
          final name = attribute.name.local.toLowerCase();
          return name == 'src' || name == 'href';
        })
        .map((attribute) => attribute.value.trim())
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    if (source == null) return;
    final assetId = imageResolver(source);
    if (assetId == null || assetId.isEmpty) return;
    operations.add({
      'insert': {'bookImage': assetId},
    });
    if (appendNewline) operations.add({'insert': '\n'});
  }

  static void _trimBlockRuns(List<Map<String, dynamic>> operations, int start) {
    if (operations.length == start) return;
    final first = operations[start];
    if (first['insert'] is String) {
      first['insert'] = (first['insert'] as String).trimLeft();
    }
    final last = operations.last;
    if (last['insert'] is String) {
      last['insert'] = (last['insert'] as String).trimRight();
    }
    operations.removeWhere((operation) => operation['insert'] == '');
  }

  static String _normalized(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ');

  static bool _isVerseContainer(XmlElement element) {
    final tag = element.name.local.toLowerCase();
    if (const {'poem', 'poetry', 'verse', 'stanza', 'v'}.contains(tag)) {
      return true;
    }
    final classes = (element.getAttribute('class') ?? '').toLowerCase().split(
      RegExp(r'\s+'),
    );
    return classes.any(
      (name) => const {'poem', 'poetry', 'verse', 'stanza'}.contains(name),
    );
  }
}
