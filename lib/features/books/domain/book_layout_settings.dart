import 'package:dnevnik/features/books/domain/book_page_format.dart';
import 'package:dnevnik/features/books/domain/book_page_view_mode.dart';

enum BookPaperSize { a4 }

enum BookPageOrientation { portrait, landscape }

class BookLayoutSettings {
  const BookLayoutSettings({
    this.paperSize = BookPaperSize.a4,
    this.orientation = BookPageOrientation.portrait,
    this.marginTopMm = 20,
    this.marginRightMm = 20,
    this.marginBottomMm = 20,
    this.marginLeftMm = 20,
    this.viewMode = BookPageViewMode.continuous,
    this.showChapterTitlesInBody = true,
  });

  factory BookLayoutSettings.fromJson(Map<String, dynamic> json) =>
      BookLayoutSettings(
        paperSize: _enumValue(
          BookPaperSize.values,
          json['paperSize']?.toString(),
          BookPaperSize.a4,
        ),
        orientation: _enumValue(
          BookPageOrientation.values,
          json['orientation']?.toString(),
          BookPageOrientation.portrait,
        ),
        marginTopMm: _margin(json['marginTopMm']),
        marginRightMm: _margin(json['marginRightMm']),
        marginBottomMm: _margin(json['marginBottomMm']),
        marginLeftMm: _margin(json['marginLeftMm']),
        viewMode: _enumValue(
          BookPageViewMode.values,
          json['viewMode']?.toString(),
          BookPageViewMode.continuous,
        ),
        showChapterTitlesInBody: json['showChapterTitlesInBody'] != false,
      );

  final BookPaperSize paperSize;
  final BookPageOrientation orientation;
  final double marginTopMm;
  final double marginRightMm;
  final double marginBottomMm;
  final double marginLeftMm;
  final BookPageViewMode viewMode;
  final bool showChapterTitlesInBody;

  BookPageFormat get pageFormat {
    final (widthMm, heightMm) = switch ((paperSize, orientation)) {
      (BookPaperSize.a4, BookPageOrientation.portrait) => (210.0, 297.0),
      (BookPaperSize.a4, BookPageOrientation.landscape) => (297.0, 210.0),
    };
    return BookPageFormat(
      widthMm: widthMm,
      heightMm: heightMm,
      marginTopMm: marginTopMm,
      marginRightMm: marginRightMm,
      marginBottomMm: marginBottomMm,
      marginLeftMm: marginLeftMm,
    );
  }

  BookLayoutSettings copyWith({
    BookPaperSize? paperSize,
    BookPageOrientation? orientation,
    double? marginTopMm,
    double? marginRightMm,
    double? marginBottomMm,
    double? marginLeftMm,
    BookPageViewMode? viewMode,
    bool? showChapterTitlesInBody,
  }) => BookLayoutSettings(
    paperSize: paperSize ?? this.paperSize,
    orientation: orientation ?? this.orientation,
    marginTopMm: marginTopMm ?? this.marginTopMm,
    marginRightMm: marginRightMm ?? this.marginRightMm,
    marginBottomMm: marginBottomMm ?? this.marginBottomMm,
    marginLeftMm: marginLeftMm ?? this.marginLeftMm,
    viewMode: viewMode ?? this.viewMode,
    showChapterTitlesInBody:
        showChapterTitlesInBody ?? this.showChapterTitlesInBody,
  );

  BookLayoutSettings withUniformMargins(double millimeters) => copyWith(
    marginTopMm: millimeters,
    marginRightMm: millimeters,
    marginBottomMm: millimeters,
    marginLeftMm: millimeters,
  );

  Map<String, Object> toJson() => {
    'paperSize': paperSize.name,
    'orientation': orientation.name,
    'marginTopMm': marginTopMm,
    'marginRightMm': marginRightMm,
    'marginBottomMm': marginBottomMm,
    'marginLeftMm': marginLeftMm,
    'viewMode': viewMode.name,
    'showChapterTitlesInBody': showChapterTitlesInBody,
  };

  static double _margin(Object? value) {
    final parsed = value is num ? value.toDouble() : 20.0;
    return parsed.clamp(5, 50).toDouble();
  }
}

T _enumValue<T extends Enum>(List<T> values, String? name, T fallback) =>
    values.where((value) => value.name == name).firstOrNull ?? fallback;
