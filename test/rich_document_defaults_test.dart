import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('removes only the legacy automatic line height', () {
    final normalized = withoutLegacyDefaultLineHeight([
      {
        'insert': 'Первый\n',
        'attributes': {'line-height': '1.5'},
      },
      {
        'insert': 'Второй\n',
        'attributes': {'line-height': '2.0', 'align': 'center'},
      },
    ]);

    expect(normalized.first.containsKey('attributes'), isFalse);
    expect(normalized.last['attributes'], {
      'line-height': '2.0',
      'align': 'center',
    });
  });
}
