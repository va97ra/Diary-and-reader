import 'package:dnevnik/app/diary_app.dart';
import 'package:dnevnik/features/diary/application/diary_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_diary_repository.dart';

void main() {
  testWidgets('opens the diary from the book cover', (tester) async {
    final controller = DiaryController(MemoryDiaryRepository());
    await controller.load(preferredLanguage: 'ru');

    await tester.pumpWidget(DiaryApp(controller: controller));
    expect(find.text('Мой дневник'), findsOneWidget);

    await tester.tap(find.text('Открыть книгу'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(find.text('Новая запись'), findsWidgets);
  });
}
