import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:xml/xml.dart';

typedef BookImageResolver = String? Function(String source);

abstract final class XmlBookContentConverter {
  /// A line break inside a paragraph, as `<br/>` means in markup.
  static const _lineBreak = '\u2028';

  /// Elements that flow inside a paragraph rather than start a new one.
  static const _inlineTags = {
    'a',
    'abbr',
    'acronym',
    'b',
    'bdi',
    'bdo',
    'big',
    'br',
    'code',
    'del',
    'dfn',
    'em',
    'emphasis',
    'font',
    'i',
    'ins',
    'kbd',
    'mark',
    'q',
    's',
    'samp',
    'small',
    'span',
    'strike',
    'strikethrough',
    'strong',
    'sub',
    'sup',
    'time',
    'tt',
    'u',
    'var',
  };

  static final _spacedLineBreak = RegExp(' *$_lineBreak *');
  static final _leadingSpaces = RegExp('^ +');
  static final _trailingSpaces = RegExp(r' +$');

  static RichDocument convert(
    Iterable<XmlNode> nodes, {
    BookImageResolver? imageResolver,
  }) {
    final operations = <Map<String, dynamic>>[];
    _appendChildren(nodes, operations, imageResolver);
    return operations.isEmpty ? emptyRichDocument() : operations;
  }

  /// Appends container content: block children as their own blocks, and each
  /// run of text and inline elements between them as one paragraph, so a
  /// link or a stray space never splits or pads the text around it.
  static void _appendChildren(
    Iterable<XmlNode> nodes,
    List<Map<String, dynamic>> operations,
    BookImageResolver? imageResolver,
  ) {
    final inlineRun = <XmlNode>[];
    void flushInlineRun() {
      if (inlineRun.isEmpty) return;
      _appendParagraph(
        List.of(inlineRun),
        operations,
        imageResolver: imageResolver,
      );
      inlineRun.clear();
    }

    for (final node in nodes) {
      // Comments and processing instructions neither show nor split text.
      if (node is! XmlText && node is! XmlElement) continue;
      if (_isInline(node)) {
        inlineRun.add(node);
        continue;
      }
      flushInlineRun();
      _appendNode(node, operations, imageResolver);
    }
    flushInlineRun();
  }

  /// Text, or an inline element holding nothing but inline content; a link
  /// wrapped around whole blocks still reads as those blocks.
  static bool _isInline(XmlNode node) {
    if (node is XmlText) return true;
    if (node is! XmlElement || _isVerseContainer(node)) return false;
    return _inlineTags.contains(node.name.local.toLowerCase()) &&
        node.descendantElements.every((element) {
          final tag = element.name.local.toLowerCase();
          return _inlineTags.contains(tag) || tag == 'img' || tag == 'image';
        });
  }

  static void _appendNode(
    XmlNode node,
    List<Map<String, dynamic>> operations,
    BookImageResolver? imageResolver,
  ) {
    if (node is! XmlElement) return;
    final tag = node.name.local.toLowerCase();
    if (_isVerseContainer(node)) {
      _appendParagraph(
        [node],
        operations,
        softLineBreaks: true,
        imageResolver: imageResolver,
      );
      return;
    }
    switch (tag) {
      case 'p':
        _appendParagraph([node], operations, imageResolver: imageResolver);
      case 'subtitle':
        _appendParagraph(
          [node],
          operations,
          blockAttributes: const {'header': 2},
          imageResolver: imageResolver,
        );
      case 'h1':
        _appendParagraph(
          [node],
          operations,
          blockAttributes: const {'header': 1},
          imageResolver: imageResolver,
        );
      case 'h2':
        _appendParagraph(
          [node],
          operations,
          blockAttributes: const {'header': 2},
          imageResolver: imageResolver,
        );
      case 'h3' || 'h4' || 'h5' || 'h6':
        _appendParagraph(
          [node],
          operations,
          blockAttributes: const {'header': 3},
          imageResolver: imageResolver,
        );
      case 'blockquote':
        final paragraphs = _directReadableBlocks(node);
        for (final paragraph in paragraphs.isEmpty ? [node] : paragraphs) {
          _appendParagraph(
            [paragraph],
            operations,
            blockAttributes: const {'blockquote': true},
            imageResolver: imageResolver,
          );
        }
      case 'cite':
        for (final paragraph in _directReadableBlocks(node)) {
          _appendParagraph(
            [paragraph],
            operations,
            blockAttributes: const {'blockquote': true},
            imageResolver: imageResolver,
          );
        }
      case 'pre':
        _appendParagraph(
          [node],
          operations,
          blockAttributes: const {'code-block': true},
          raw: true,
          imageResolver: imageResolver,
        );
      case 'li':
        final list = node.parentElement?.name.local.toLowerCase() == 'ol'
            ? 'ordered'
            : 'bullet';
        _appendParagraph(
          [node],
          operations,
          blockAttributes: {'list': list},
          imageResolver: imageResolver,
        );
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
        _appendChildren(node.children, operations, imageResolver);
    }
  }

  static List<XmlElement> _directReadableBlocks(XmlElement parent) => parent
      .childElements
      .where((element) => const {'p', 'subtitle'}.contains(element.name.local))
      .toList();

  /// Appends [nodes] as one paragraph whose closing line break carries
  /// [blockAttributes]; nothing at all when they hold no readable content.
  static void _appendParagraph(
    Iterable<XmlNode> nodes,
    List<Map<String, dynamic>> operations, {
    Map<String, dynamic> blockAttributes = const {},
    bool raw = false,
    bool softLineBreaks = false,
    BookImageResolver? imageResolver,
  }) {
    final start = operations.length;
    for (final node in nodes) {
      _appendInline(
        node,
        const {},
        operations,
        raw: raw,
        imageResolver: imageResolver,
        softLineBreaks: softLineBreaks,
      );
    }
    _trimBlockRuns(operations, start, raw: raw);
    if (operations.length == start) return;
    operations.add({
      'insert': '\n',
      if (blockAttributes.isNotEmpty) 'attributes': blockAttributes,
    });
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
      // A new paragraph here would drop the block's style, such as a
      // heading, from the text before the break.
      operations.add({'insert': _lineBreak});
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
    if (softLineBreaks && (tag == 'v' || tag == 'stanza')) {
      operations.add({'insert': _lineBreak});
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

  /// Removes the whitespace markup leaves at the edges of the block started
  /// at [start] and around its line breaks, then drops runs left empty.
  /// [raw] text keeps its inner spacing.
  static void _trimBlockRuns(
    List<Map<String, dynamic>> operations,
    int start, {
    bool raw = false,
  }) {
    if (operations.length == start) return;
    if (!raw) {
      Map<String, dynamic>? previousText;
      var atBlockStart = true;
      var atLineStart = true;
      for (var index = start; index < operations.length; index++) {
        final operation = operations[index];
        final insert = operation['insert'];
        if (insert is! String) {
          previousText = null;
          atBlockStart = atLineStart = false;
          continue;
        }
        var text = insert.replaceAll(_spacedLineBreak, _lineBreak);
        if (atBlockStart) {
          text = text.trimLeft();
        } else if (atLineStart) {
          text = text.replaceFirst(_leadingSpaces, '');
        }
        if (text.startsWith(_lineBreak) && previousText != null) {
          previousText['insert'] = (previousText['insert'] as String)
              .replaceFirst(_trailingSpaces, '');
        }
        operation['insert'] = text;
        if (text.isEmpty) continue;
        previousText = operation;
        atBlockStart = false;
        atLineStart = text.endsWith(_lineBreak);
      }
    }
    final first = operations[start];
    if (first['insert'] is String) {
      first['insert'] = (first['insert'] as String).trimLeft();
    }
    for (var index = operations.length - 1; index >= start; index--) {
      final insert = operations[index]['insert'];
      if (insert is! String) break;
      final trimmed = insert.trimRight();
      operations[index]['insert'] = trimmed;
      if (trimmed.isNotEmpty) break;
    }
    final kept = [
      for (final operation in operations.skip(start))
        if (operation['insert'] != '') operation,
    ];
    operations
      ..removeRange(start, operations.length)
      ..addAll(kept);
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
