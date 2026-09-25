import 'package:flutter/painting.dart';

/// Colours an author can give to words. They read well on the paper page of
/// the editor; the reader lightens them for its dark theme.
abstract final class BookTextColors {
  static const palette = <(String id, Color color)>[
    ('red', Color(0xFFC62828)),
    ('burgundy', Color(0xFF8E244D)),
    ('orange', Color(0xFFD84315)),
    ('brown', Color(0xFF6D4C41)),
    ('green', Color(0xFF2E7D32)),
    ('teal', Color(0xFF00796B)),
    ('blue', Color(0xFF1565C0)),
    ('purple', Color(0xFF6A1B9A)),
    ('gray', Color(0xFF616161)),
  ];

  /// [color] as a document stores it, such as `#c62828`.
  static String hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
