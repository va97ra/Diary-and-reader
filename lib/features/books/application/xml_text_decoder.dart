import 'dart:convert';
import 'dart:typed_data';

abstract final class XmlTextDecoder {
  static String decode(Uint8List bytes) {
    if (bytes.length >= 2) {
      if (bytes[0] == 0xff && bytes[1] == 0xfe) {
        return _utf16(bytes.sublist(2), Endian.little);
      }
      if (bytes[0] == 0xfe && bytes[1] == 0xff) {
        return _utf16(bytes.sublist(2), Endian.big);
      }
    }
    final declaration = latin1
        .decode(bytes.take(256).toList(), allowInvalid: true)
        .toLowerCase();
    final encoding = RegExp(
      r'''encoding\s*=\s*["']([^"']+)["']''',
    ).firstMatch(declaration)?.group(1);
    if (encoding == 'windows-1251' || encoding == 'cp1251') {
      return _windows1251(bytes);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  static String normalizeEntities(String source) => source
      .replaceAll('&nbsp;', '&#160;')
      .replaceAll('&copy;', '&#169;')
      .replaceAll('&ndash;', '&#8211;')
      .replaceAll('&mdash;', '&#8212;')
      .replaceAll('&laquo;', '&#171;')
      .replaceAll('&raquo;', '&#187;');

  static String _utf16(Uint8List bytes, Endian endian) {
    final data = ByteData.sublistView(bytes);
    final units = <int>[];
    for (var offset = 0; offset + 1 < data.lengthInBytes; offset += 2) {
      units.add(data.getUint16(offset, endian));
    }
    return String.fromCharCodes(units);
  }

  static String _windows1251(Uint8List bytes) => String.fromCharCodes(
    bytes.map((byte) => byte < 0x80 ? byte : _windows1251Table[byte - 0x80]),
  );

  static const _windows1251Table = <int>[
    0x0402,
    0x0403,
    0x201a,
    0x0453,
    0x201e,
    0x2026,
    0x2020,
    0x2021,
    0x20ac,
    0x2030,
    0x0409,
    0x2039,
    0x040a,
    0x040c,
    0x040b,
    0x040f,
    0x0452,
    0x2018,
    0x2019,
    0x201c,
    0x201d,
    0x2022,
    0x2013,
    0x2014,
    0xfffd,
    0x2122,
    0x0459,
    0x203a,
    0x045a,
    0x045c,
    0x045b,
    0x045f,
    0x00a0,
    0x040e,
    0x045e,
    0x0408,
    0x00a4,
    0x0490,
    0x00a6,
    0x00a7,
    0x0401,
    0x00a9,
    0x0404,
    0x00ab,
    0x00ac,
    0x00ad,
    0x00ae,
    0x0407,
    0x00b0,
    0x00b1,
    0x0406,
    0x0456,
    0x0491,
    0x00b5,
    0x00b6,
    0x00b7,
    0x0451,
    0x2116,
    0x0454,
    0x00bb,
    0x0458,
    0x0405,
    0x0455,
    0x0457,
    0x0410,
    0x0411,
    0x0412,
    0x0413,
    0x0414,
    0x0415,
    0x0416,
    0x0417,
    0x0418,
    0x0419,
    0x041a,
    0x041b,
    0x041c,
    0x041d,
    0x041e,
    0x041f,
    0x0420,
    0x0421,
    0x0422,
    0x0423,
    0x0424,
    0x0425,
    0x0426,
    0x0427,
    0x0428,
    0x0429,
    0x042a,
    0x042b,
    0x042c,
    0x042d,
    0x042e,
    0x042f,
    0x0430,
    0x0431,
    0x0432,
    0x0433,
    0x0434,
    0x0435,
    0x0436,
    0x0437,
    0x0438,
    0x0439,
    0x043a,
    0x043b,
    0x043c,
    0x043d,
    0x043e,
    0x043f,
    0x0440,
    0x0441,
    0x0442,
    0x0443,
    0x0444,
    0x0445,
    0x0446,
    0x0447,
    0x0448,
    0x0449,
    0x044a,
    0x044b,
    0x044c,
    0x044d,
    0x044e,
    0x044f,
  ];
}
