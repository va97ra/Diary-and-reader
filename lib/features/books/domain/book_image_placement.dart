import 'dart:convert';

enum BookImageAlignment { left, center, right }

class BookImagePlacement {
  const BookImagePlacement({
    required this.assetId,
    this.alignment = BookImageAlignment.center,
    this.widthPercent = 100,
    this.caption = '',
  });

  factory BookImagePlacement.decode(String data) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map) {
        final json = Map<String, dynamic>.from(decoded);
        final assetId = json['assetId']?.toString().trim() ?? '';
        if (assetId.isNotEmpty) {
          final width = _int(json['widthPercent']);
          return BookImagePlacement(
            assetId: assetId,
            alignment: BookImageAlignment.values.firstWhere(
              (value) => value.name == json['alignment']?.toString(),
              orElse: () => BookImageAlignment.center,
            ),
            widthPercent: _supportedWidth(width),
            caption: json['caption']?.toString().trim() ?? '',
          );
        }
      }
    } on FormatException {
      // Legacy embeds stored only the asset id.
    }
    return BookImagePlacement(assetId: data);
  }

  final String assetId;
  final BookImageAlignment alignment;
  final int widthPercent;
  final String caption;

  String encode() => jsonEncode({
    'assetId': assetId,
    'alignment': alignment.name,
    'widthPercent': widthPercent,
    if (caption.trim().isNotEmpty) 'caption': caption.trim(),
  });

  BookImagePlacement copyWith({
    String? assetId,
    BookImageAlignment? alignment,
    int? widthPercent,
    String? caption,
  }) => BookImagePlacement(
    assetId: assetId ?? this.assetId,
    alignment: alignment ?? this.alignment,
    widthPercent: _supportedWidth(widthPercent ?? this.widthPercent),
    caption: caption ?? this.caption,
  );

  static int? _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');

  static int _supportedWidth(int? value) => (value ?? 100).clamp(20, 100);
}
