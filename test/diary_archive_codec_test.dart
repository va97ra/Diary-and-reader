import 'package:dnevnik/features/diary/application/diary_archive_codec.dart';
import 'package:dnevnik/features/diary/domain/diary_entry.dart';
import 'package:dnevnik/features/diary/domain/diary_snapshot.dart';
import 'package:dnevnik/features/diary/domain/page_margins.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips a versioned diary archive', () {
    final entry = DiaryEntry.create(title: 'Archive entry');
    final snapshot = DiarySnapshot(
      entries: [entry],
      activeEntryId: entry.id,
      languageCode: 'en',
      margins: const PageMargins.wide(),
    );

    final restored = DiaryArchiveCodec.decode(
      DiaryArchiveCodec.encode(snapshot),
    );

    expect(restored.entries.single.title, 'Archive entry');
    expect(restored.activeEntryId, entry.id);
    expect(restored.languageCode, 'en');
    expect(restored.margins.top, 30);
  });

  test('rejects an unknown archive format', () {
    expect(
      () => DiaryArchiveCodec.decode('{"format":"unknown","version":1}'),
      throwsFormatException,
    );
  });
}
