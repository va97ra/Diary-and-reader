enum BookReaderTheme { light, sepia, dark }

enum BookReaderViewMode { continuous, singlePage, spread }

class BookReaderSettings {
  const BookReaderSettings({
    this.theme = BookReaderTheme.sepia,
    this.viewMode = BookReaderViewMode.continuous,
    this.fontFamily = 'Georgia',
    this.fontSize = 18,
    this.lineHeight = 1.6,
    this.contentWidth = 720,
    this.horizontalPadding = 32,
    this.verticalPadding = 24,
    this.fontWeight = 400,
    this.justifyText = false,
    this.centerTapControls = true,
    this.swipeChapterNavigation = true,
    this.speechRate = 0.5,
    this.speechPitch = 1,
  });

  factory BookReaderSettings.fromJson(Map<String, dynamic> json) =>
      BookReaderSettings(
        theme:
            BookReaderTheme.values
                .where((value) => value.name == json['theme']?.toString())
                .firstOrNull ??
            BookReaderTheme.sepia,
        viewMode:
            BookReaderViewMode.values
                .where((value) => value.name == json['viewMode']?.toString())
                .firstOrNull ??
            BookReaderViewMode.continuous,
        fontFamily: _readerFontFamily(json['fontFamily']),
        fontSize: _bounded(json['fontSize'], 12, 32, 18),
        lineHeight: _bounded(json['lineHeight'], 1.2, 2.2, 1.6),
        contentWidth: _bounded(json['contentWidth'], 480, 1000, 720),
        horizontalPadding: _bounded(json['horizontalPadding'], 16, 96, 32),
        verticalPadding: _bounded(json['verticalPadding'], 12, 80, 24),
        fontWeight: _bounded(json['fontWeight'], 300, 700, 400),
        justifyText: json['justifyText'] == true,
        centerTapControls: json['centerTapControls'] != false,
        swipeChapterNavigation: json['swipeChapterNavigation'] != false,
        speechRate: _bounded(json['speechRate'], 0.25, 0.75, 0.5),
        speechPitch: _bounded(json['speechPitch'], 0.5, 1.5, 1),
      );

  final BookReaderTheme theme;
  final BookReaderViewMode viewMode;
  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final double contentWidth;
  final double horizontalPadding;
  final double verticalPadding;
  final double fontWeight;
  final bool justifyText;
  final bool centerTapControls;
  final bool swipeChapterNavigation;
  final double speechRate;
  final double speechPitch;

  BookReaderSettings copyWith({
    BookReaderTheme? theme,
    BookReaderViewMode? viewMode,
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    double? contentWidth,
    double? horizontalPadding,
    double? verticalPadding,
    double? fontWeight,
    bool? justifyText,
    bool? centerTapControls,
    bool? swipeChapterNavigation,
    double? speechRate,
    double? speechPitch,
  }) => BookReaderSettings(
    theme: theme ?? this.theme,
    viewMode: viewMode ?? this.viewMode,
    fontFamily: _readerFontFamily(fontFamily ?? this.fontFamily),
    fontSize: (fontSize ?? this.fontSize).clamp(12, 32),
    lineHeight: (lineHeight ?? this.lineHeight).clamp(1.2, 2.2),
    contentWidth: (contentWidth ?? this.contentWidth).clamp(480, 1000),
    horizontalPadding: (horizontalPadding ?? this.horizontalPadding).clamp(
      16,
      96,
    ),
    verticalPadding: (verticalPadding ?? this.verticalPadding).clamp(12, 80),
    fontWeight: (fontWeight ?? this.fontWeight).clamp(300, 700),
    justifyText: justifyText ?? this.justifyText,
    centerTapControls: centerTapControls ?? this.centerTapControls,
    swipeChapterNavigation:
        swipeChapterNavigation ?? this.swipeChapterNavigation,
    speechRate: (speechRate ?? this.speechRate).clamp(0.25, 0.75),
    speechPitch: (speechPitch ?? this.speechPitch).clamp(0.5, 1.5),
  );

  Map<String, Object> toJson() => {
    'theme': theme.name,
    'viewMode': viewMode.name,
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'lineHeight': lineHeight,
    'contentWidth': contentWidth,
    'horizontalPadding': horizontalPadding,
    'verticalPadding': verticalPadding,
    'fontWeight': fontWeight,
    'justifyText': justifyText,
    'centerTapControls': centerTapControls,
    'swipeChapterNavigation': swipeChapterNavigation,
    'speechRate': speechRate,
    'speechPitch': speechPitch,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookReaderSettings &&
          theme == other.theme &&
          viewMode == other.viewMode &&
          fontFamily == other.fontFamily &&
          fontSize == other.fontSize &&
          lineHeight == other.lineHeight &&
          contentWidth == other.contentWidth &&
          horizontalPadding == other.horizontalPadding &&
          verticalPadding == other.verticalPadding &&
          fontWeight == other.fontWeight &&
          justifyText == other.justifyText &&
          centerTapControls == other.centerTapControls &&
          swipeChapterNavigation == other.swipeChapterNavigation &&
          speechRate == other.speechRate &&
          speechPitch == other.speechPitch;

  @override
  int get hashCode => Object.hash(
    theme,
    viewMode,
    fontFamily,
    fontSize,
    lineHeight,
    contentWidth,
    horizontalPadding,
    verticalPadding,
    fontWeight,
    justifyText,
    centerTapControls,
    swipeChapterNavigation,
    speechRate,
    speechPitch,
  );
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
