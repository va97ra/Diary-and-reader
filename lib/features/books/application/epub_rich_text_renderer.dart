import 'package:dnevnik/features/books/domain/rich_document.dart';

abstract final class EpubRichTextRenderer {
  static String render(RichDocument document) {
    final lines = _lines(document);
    final output = StringBuffer();
    String? openList;

    void closeList() {
      if (openList == null) return;
      output.writeln('</$openList>');
      openList = null;
    }

    for (final line in lines) {
      final list = line.attributes['list']?.toString();
      final listTag = list == 'ordered'
          ? 'ol'
          : list == null
          ? null
          : 'ul';
      if (listTag != null) {
        if (openList != listTag) {
          closeList();
          output.writeln('<$listTag>');
          openList = listTag;
        }
        final checkbox = switch (list) {
          'checked' => '<span class="check">☑</span> ',
          'unchecked' => '<span class="check">☐</span> ',
          _ => '',
        };
        output.writeln(
          '<li${_blockAttributes(line.attributes)}>$checkbox${line.html}</li>',
        );
        continue;
      }

      closeList();
      final header = _integer(line.attributes['header']);
      final tag = switch (header) {
        1 => 'h2',
        2 => 'h3',
        3 => 'h4',
        _ when line.attributes['blockquote'] == true => 'blockquote',
        _ when line.attributes['code-block'] == true => 'pre',
        _ => 'p',
      };
      output.writeln(
        '<$tag${_blockAttributes(line.attributes)}>${line.html}</$tag>',
      );
    }
    closeList();
    return output.toString();
  }

  static List<_EpubLine> _lines(RichDocument document) {
    final lines = <_EpubLine>[];
    var fragments = <String>[];

    void finish(Map<String, dynamic> attributes) {
      lines.add(
        _EpubLine(
          html: fragments.isEmpty ? '&#160;' : fragments.join(),
          attributes: attributes,
        ),
      );
      fragments = <String>[];
    }

    for (final operation in document) {
      final insert = operation['insert'];
      if (insert is! String) continue;
      final attributes = operation['attributes'] is Map
          ? Map<String, dynamic>.from(operation['attributes'] as Map)
          : const <String, dynamic>{};
      final parts = insert.split('\n');
      for (var index = 0; index < parts.length; index++) {
        if (parts[index].isNotEmpty) {
          fragments.add(_inline(parts[index], attributes));
        }
        if (index < parts.length - 1) finish(attributes);
      }
    }
    if (fragments.isNotEmpty) finish(const <String, dynamic>{});
    return lines.isEmpty
        ? const [_EpubLine(html: '&#160;', attributes: {})]
        : lines;
  }

  static String _inline(String text, Map<String, dynamic> attributes) {
    var html = escapeXml(text);
    final link = attributes['link']?.toString().trim();
    final size = double.tryParse(attributes['size']?.toString() ?? '');
    final font = attributes['font']?.toString().trim();
    final styles = <String>[
      if (size != null && size >= 6 && size <= 96)
        'font-size:${_number(size * 0.75)}pt',
      if (font != null && font.isNotEmpty)
        'font-family:&quot;${escapeXml(font)}&quot;',
    ];
    if (styles.isNotEmpty) {
      html = '<span style="${styles.join(';')}">$html</span>';
    }
    if (attributes['code'] == true) html = '<code>$html</code>';
    if (attributes['bold'] == true) html = '<strong>$html</strong>';
    if (attributes['italic'] == true) html = '<em>$html</em>';
    if (attributes['underline'] == true) html = '<u>$html</u>';
    if (attributes['strike'] == true) html = '<s>$html</s>';
    if (attributes['script'] == 'super') html = '<sup>$html</sup>';
    if (attributes['script'] == 'sub') html = '<sub>$html</sub>';
    if (link != null && _safeLink(link)) {
      html = '<a href="${escapeXml(link)}">$html</a>';
    }
    return html;
  }

  static String _blockAttributes(Map<String, dynamic> attributes) {
    final classes = <String>[];
    final align = attributes['align']?.toString();
    if (const {'center', 'right', 'justify'}.contains(align)) {
      classes.add('align-$align');
    }
    final indent = _integer(attributes['indent']);
    if (indent != null && indent > 0) {
      classes.add('indent-${indent.clamp(1, 8)}');
    }
    final semantic = attributes['bookParagraphStyle']?.toString();
    if (semantic == 'epigraph') classes.add('epigraph');
    if (semantic == 'sceneBreak') classes.add('scene-break');
    final direction = attributes['direction'] == 'rtl' ? ' dir="rtl"' : '';
    final lineHeight = double.tryParse(
      attributes['line-height']?.toString() ?? '',
    );
    final style = lineHeight != null && lineHeight >= 1 && lineHeight <= 3
        ? ' style="line-height:${_number(lineHeight)}"'
        : '';
    final className = classes.isEmpty ? '' : ' class="${classes.join(' ')}"';
    return '$className$direction$style';
  }

  static bool _safeLink(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme.isEmpty ||
            const {'http', 'https', 'mailto'}.contains(uri.scheme));
  }

  static int? _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
}

String escapeXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

class _EpubLine {
  const _EpubLine({required this.html, required this.attributes});

  final String html;
  final Map<String, dynamic> attributes;
}
