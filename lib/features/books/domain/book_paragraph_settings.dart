enum BookParagraphPreset { modern, classic, manuscript, custom }

class BookParagraphSettings {
  const BookParagraphSettings({
    this.preset = BookParagraphPreset.custom,
    this.fontFamily = 'Georgia',
    this.fontSizePt = 12,
    this.lineHeight = 1.5,
    this.paragraphIndentMm = 0,
    this.spacingBeforePt = 0,
    this.spacingAfterPt = 0,
  });

  factory BookParagraphSettings.fromJson(Map<String, dynamic> json) =>
      BookParagraphSettings(
        preset: _enumValue(
          BookParagraphPreset.values,
          json['preset']?.toString(),
          BookParagraphPreset.custom,
        ),
        fontFamily: _fontFamily(json['fontFamily']),
        fontSizePt: _bounded(json['fontSizePt'], 8, 36, 12),
        lineHeight: _bounded(json['lineHeight'], 1, 2.5, 1.5),
        paragraphIndentMm: _bounded(json['paragraphIndentMm'], 0, 30, 0),
        spacingBeforePt: _bounded(json['spacingBeforePt'], 0, 72, 0),
        spacingAfterPt: _bounded(json['spacingAfterPt'], 0, 72, 0),
      );

  factory BookParagraphSettings.forPreset(BookParagraphPreset preset) =>
      switch (preset) {
        BookParagraphPreset.modern => const BookParagraphSettings(
          preset: BookParagraphPreset.modern,
          spacingAfterPt: 8,
        ),
        BookParagraphPreset.classic => const BookParagraphSettings(
          preset: BookParagraphPreset.classic,
          lineHeight: 1.35,
          paragraphIndentMm: 5,
          spacingAfterPt: 0,
        ),
        BookParagraphPreset.manuscript => const BookParagraphSettings(
          preset: BookParagraphPreset.manuscript,
          fontFamily: 'Times New Roman',
          lineHeight: 2,
          paragraphIndentMm: 12.7,
          spacingAfterPt: 0,
        ),
        BookParagraphPreset.custom => const BookParagraphSettings(
          preset: BookParagraphPreset.custom,
        ),
      };

  final BookParagraphPreset preset;
  final String fontFamily;
  final double fontSizePt;
  final double lineHeight;
  final double paragraphIndentMm;
  final double spacingBeforePt;
  final double spacingAfterPt;

  BookParagraphSettings copyWith({
    BookParagraphPreset? preset,
    String? fontFamily,
    double? fontSizePt,
    double? lineHeight,
    double? paragraphIndentMm,
    double? spacingBeforePt,
    double? spacingAfterPt,
    bool markCustom = true,
  }) => BookParagraphSettings(
    preset: preset ?? (markCustom ? BookParagraphPreset.custom : this.preset),
    fontFamily: _fontFamily(fontFamily ?? this.fontFamily),
    fontSizePt: (fontSizePt ?? this.fontSizePt).clamp(8, 36),
    lineHeight: (lineHeight ?? this.lineHeight).clamp(1, 2.5),
    paragraphIndentMm: (paragraphIndentMm ?? this.paragraphIndentMm).clamp(
      0,
      30,
    ),
    spacingBeforePt: (spacingBeforePt ?? this.spacingBeforePt).clamp(0, 72),
    spacingAfterPt: (spacingAfterPt ?? this.spacingAfterPt).clamp(0, 72),
  );

  Map<String, Object> toJson() => {
    'preset': preset.name,
    'fontFamily': fontFamily,
    'fontSizePt': fontSizePt,
    'lineHeight': lineHeight,
    'paragraphIndentMm': paragraphIndentMm,
    'spacingBeforePt': spacingBeforePt,
    'spacingAfterPt': spacingAfterPt,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookParagraphSettings &&
          preset == other.preset &&
          fontFamily == other.fontFamily &&
          fontSizePt == other.fontSizePt &&
          lineHeight == other.lineHeight &&
          paragraphIndentMm == other.paragraphIndentMm &&
          spacingBeforePt == other.spacingBeforePt &&
          spacingAfterPt == other.spacingAfterPt;

  @override
  int get hashCode => Object.hash(
    preset,
    fontFamily,
    fontSizePt,
    lineHeight,
    paragraphIndentMm,
    spacingBeforePt,
    spacingAfterPt,
  );
}

const bookFontFamilies = <String>[
  'Georgia',
  'Times New Roman',
  'Arial',
  'Calibri',
  'Verdana',
  'Tahoma',
  'Courier New',
];

T _enumValue<T extends Enum>(List<T> values, String? name, T fallback) =>
    values.where((value) => value.name == name).firstOrNull ?? fallback;

double _bounded(
  Object? value,
  double minimum,
  double maximum,
  double fallback,
) {
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  return (parsed ?? fallback).clamp(minimum, maximum).toDouble();
}

String _fontFamily(Object? value) {
  final requested = value?.toString();
  return bookFontFamilies.contains(requested) ? requested! : 'Georgia';
}
