enum BookReaderTheme { light, sepia, dark }

class BookReaderSettings {
  const BookReaderSettings({
    this.theme = BookReaderTheme.sepia,
    this.fontFamily = 'Georgia',
    this.fontSize = 18,
    this.lineHeight = 1.6,
    this.contentWidth = 720,
  });

  factory BookReaderSettings.fromJson(Map<String, dynamic> json) =>
      BookReaderSettings(
        theme:
            BookReaderTheme.values
                .where((value) => value.name == json['theme']?.toString())
                .firstOrNull ??
            BookReaderTheme.sepia,
        fontFamily: _readerFontFamily(json['fontFamily']),
        fontSize: _bounded(json['fontSize'], 12, 32, 18),
        lineHeight: _bounded(json['lineHeight'], 1.2, 2.2, 1.6),
        contentWidth: _bounded(json['contentWidth'], 480, 1000, 720),
      );

  final BookReaderTheme theme;
  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final double contentWidth;

  BookReaderSettings copyWith({
    BookReaderTheme? theme,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    double? contentWidth,
  }) => BookReaderSettings(
    theme: theme ?? this.theme,
    fontFamily: _readerFontFamily(fontFamily ?? this.fontFamily),
    fontSize: (fontSize ?? this.fontSize).clamp(12, 32),
    lineHeight: (lineHeight ?? this.lineHeight).clamp(1.2, 2.2),
    contentWidth: (contentWidth ?? this.contentWidth).clamp(480, 1000),
  );

  Map<String, Object> toJson() => {
    'theme': theme.name,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'lineHeight': lineHeight,
    'contentWidth': contentWidth,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookReaderSettings &&
          theme == other.theme &&
          fontFamily == other.fontFamily &&
          fontSize == other.fontSize &&
          lineHeight == other.lineHeight &&
          contentWidth == other.contentWidth;

  @override
  int get hashCode =>
      Object.hash(theme, fontFamily, fontSize, lineHeight, contentWidth);
}

const bookReaderFontFamilies = <String>[
  'Georgia',
  'Times New Roman',
  'Arial',
  'Verdana',
];

double _bounded(
  Object? value,
  double minimum,
  double maximum,
  double fallback,
) {
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  return (parsed ?? fallback).clamp(minimum, maximum).toDouble();
}

String _readerFontFamily(Object? value) {
  final requested = value?.toString();
  return bookReaderFontFamilies.contains(requested) ? requested! : 'Georgia';
}
