class PageMargins {
  factory PageMargins.fromJson(Map<String, dynamic> json) => PageMargins(
    top: _number(json['top'], 25),
    right: _number(json['right'], 20),
    bottom: _number(json['bottom'], 25),
    left: _number(json['left'], 20),
  );
  const PageMargins({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  const PageMargins.normal() : this(top: 25, right: 20, bottom: 25, left: 20);
  const PageMargins.narrow() : this(top: 15, right: 15, bottom: 15, left: 15);
  const PageMargins.wide() : this(top: 30, right: 25, bottom: 30, left: 25);

  final double top;
  final double right;
  final double bottom;
  final double left;

  Map<String, double> toJson() => {
    'top': top,
    'right': right,
    'bottom': bottom,
    'left': left,
  };

  static double clamp(Object? value) {
    final parsed = double.tryParse(value.toString()) ?? 20;
    return parsed.clamp(5, 50).toDouble();
  }

  static double _number(Object? value, double fallback) {
    return value is num ? value.toDouble() : fallback;
  }
}
