import 'package:dnevnik/features/diary/application/diary_controller.dart';
import 'package:dnevnik/features/diary/domain/page_margins.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_diary_repository.dart';

void main() {
  test('persists entries, pages, language and margins', () async {
    final repository = MemoryDiaryRepository();
    final controller = DiaryController(repository);
    await controller.load(preferredLanguage: 'ru');

    final firstId = controller.activeEntry!.id;
    controller.updateTitle(firstId, 'Проверка');
    controller.updatePage(firstId, 0, [
      {'insert': 'Текст\n'},
    ]);
    controller.addPage(firstId);
    controller.setLanguage('en');
    controller.setMargins(const PageMargins.narrow());
    await controller.flush();

    final restored = DiaryController(repository);
    await restored.load(preferredLanguage: 'ru');

    expect(restored.activeEntry!.title, 'Проверка');
    expect(restored.activeEntry!.pages, hasLength(2));
    expect(restored.activeEntry!.pages.first.first['insert'], 'Текст\n');
    expect(restored.languageCode, 'en');
    expect(restored.margins.left, 15);
  });

  test('deleting the final entry creates a safe empty replacement', () async {
    final repository = MemoryDiaryRepository();
    final controller = DiaryController(repository);
    await controller.load(preferredLanguage: 'en');

    controller.deleteEntry(
      controller.activeEntry!.id,
      fallbackTitle: 'New entry',
    );

    expect(controller.entries, hasLength(1));
    expect(controller.activeEntry!.title, 'New entry');
  });

  test('margin input is constrained to supported values', () {
    expect(PageMargins.clamp('-20'), 5);
    expect(PageMargins.clamp('200'), 50);
    expect(PageMargins.clamp('bad value'), 20);
  });

  test('replaces current state from an exported archive', () async {
    final sourceRepository = MemoryDiaryRepository();
    final source = DiaryController(sourceRepository);
    await source.load(preferredLanguage: 'ru');
    source.updateTitle(source.activeEntry!.id, 'Imported entry');
    final archive = source.exportArchive();

    final target = DiaryController(MemoryDiaryRepository());
    await target.load(preferredLanguage: 'en');
    await target.importArchive(archive);

    expect(target.activeEntry!.title, 'Imported entry');
    expect(target.languageCode, 'ru');
  });
}
