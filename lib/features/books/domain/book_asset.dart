import 'dart:convert';
import 'dart:typed_data';

class BookAsset {
  BookAsset({
    required this.id,
    required this.mediaType,
    required Uint8List bytes,
    this.sourcePath = '',
  }) : bytes = Uint8List.fromList(bytes);

  factory BookAsset.fromJson(Map<String, dynamic> json) {
    final encoded = json['data']?.toString() ?? '';
    return BookAsset(
      id: json['id']?.toString() ?? '',
      mediaType: json['mediaType']?.toString() ?? '',
      sourcePath: json['sourcePath']?.toString() ?? '',
      bytes: encoded.isEmpty
          ? Uint8List(0)
          : Uint8List.fromList(base64Decode(encoded)),
    );
  }

  static BookAsset? tryFromJson(Map<String, dynamic> json) {
    try {
      return BookAsset.fromJson(json);
    } on FormatException {
      return null;
    }
  }

  final String id;
  final String mediaType;
  final Uint8List bytes;
  final String sourcePath;

  bool get isRenderableImage =>
      const {
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp',
      }.contains(mediaType.toLowerCase()) &&
      bytes.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'mediaType': mediaType,
    'sourcePath': sourcePath,
    'data': base64Encode(bytes),
  };
}
