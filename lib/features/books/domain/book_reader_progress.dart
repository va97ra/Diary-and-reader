class BookReaderProgress {
  const BookReaderProgress({this.sectionId, this.sectionProgress = 0});

  factory BookReaderProgress.fromJson(Map<String, dynamic> json) =>
      BookReaderProgress(
        sectionId: json['sectionId']?.toString(),
        sectionProgress: _normalized(json['sectionProgress']),
      );

  final String? sectionId;
  final double sectionProgress;

  BookReaderProgress copyWith({
    String? sectionId,
    bool clearSection = false,
    double? sectionProgress,
  }) => BookReaderProgress(
    sectionId: clearSection ? null : sectionId ?? this.sectionId,
    sectionProgress: _normalized(sectionProgress ?? this.sectionProgress),
  );

  Map<String, Object?> toJson() => {
    'sectionId': sectionId,
    'sectionProgress': sectionProgress,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookReaderProgress &&
          sectionId == other.sectionId &&
          sectionProgress == other.sectionProgress;

  @override
  int get hashCode => Object.hash(sectionId, sectionProgress);
}

double _normalized(Object? value) {
  final parsed = value is num ? value.toDouble() : double.tryParse('$value');
  if (parsed == null || !parsed.isFinite) return 0;
  return parsed.clamp(0, 1).toDouble();
}
