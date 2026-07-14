import 'package:dnevnik/app/diary_app.dart';
import 'package:dnevnik/features/diary/application/diary_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_diary_repository.dart';

void main() {
  testWidgets('moves overflowing rich text to additional pages', (
    tester,
  ) async {
    final controller = DiaryController(MemoryDiaryRepository());
    await controller.load(preferredLanguage: 'en');
    final entryId = controller.activeEntry!.id;
    controller.updatePage(entryId, 0, [
      {
        'insert': List.generate(
          180,
          (index) => 'Formatted line $index\n',
        ).join(),
        'attributes': {'bold': true},
      },
    ]);

    await tester.pumpWidget(DiaryApp(controller: controller));
    await tester.tap(find.text('Open book'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(controller.activeEntry!.pages.length, greaterThan(1));
    expect(controller.activeEntry!.pages.first.first['attributes'], {
      'bold': true,
    });
    expect(controller.activeEntry!.pages[1].first['attributes'], {
      'bold': true,
    });
    await controller.flush();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
