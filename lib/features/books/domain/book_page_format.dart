import 'dart:math' as math;

/// Physical manuscript page dimensions converted to Flutter logical pixels.
///
/// A logical pixel is treated as a CSS pixel at 96 DPI. Font sizes exposed to
/// the author remain typographic points and are converted separately.
class BookPageFormat {
  const BookPageFormat({
    required this.widthMm,
    required this.heightMm,
    required this.marginTopMm,
    required this.marginRightMm,
    required this.marginBottomMm,
    required this.marginLeftMm,
  });

  static const millimetersPerInch = 25.4;
  static const logicalPixelsPerInch = 96.0;
  static const pointsPerInch = 72.0;

  static const a4Landscape = BookPageFormat(
    widthMm: 297,
    heightMm: 210,
    marginTopMm: 20,
    marginRightMm: 20,
    marginBottomMm: 20,
    marginLeftMm: 20,
  );

  final double widthMm;
  final double heightMm;
  final double marginTopMm;
  final double marginRightMm;
  final double marginBottomMm;
  final double marginLeftMm;

  double get width => millimetersToLogicalPixels(widthMm);
  double get height => millimetersToLogicalPixels(heightMm);
  double get marginTop => millimetersToLogicalPixels(marginTopMm);
  double get marginRight => millimetersToLogicalPixels(marginRightMm);
  double get marginBottom => millimetersToLogicalPixels(marginBottomMm);
  double get marginLeft => millimetersToLogicalPixels(marginLeftMm);

  double scaleForWidth(double availableWidth) =>
      math.min(1, availableWidth / width).clamp(0.1, 1).toDouble();

  static double millimetersToLogicalPixels(double millimeters) =>
      millimeters * logicalPixelsPerInch / millimetersPerInch;

  static double pointsToLogicalPixels(double points) =>
      points * logicalPixelsPerInch / pointsPerInch;
}
