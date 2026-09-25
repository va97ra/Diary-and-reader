import 'package:dnevnik/app/author_studio_app.dart';
import 'package:dnevnik/app/desktop/literia_desktop_shell.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_author_workspace_repository.dart';

void main() {
  testWidgets('the panel beside the clock expands or hides from its bar', (
    tester,
  ) async {
    final controller = AuthorWorkspaceController(
      MemoryAuthorWorkspaceRepository(seedManuscript: false),
    );
    await controller.load(preferredLanguage: 'ru');
    final shell = _FakeDesktopShell();

    await tester.pumpWidget(
      AuthorStudioApp(controller: controller, desktopShell: shell),
    );
    await tester.pumpAndSettle();

    // An ordinary window has its title bar, so no panel bar.
    expect(find.byKey(const ValueKey('desktop-panel-bar')), findsNothing);
    final home = find.byKey(const ValueKey('home-write-tile'));
    expect(home, findsOneWidget);
    final homeState = tester.state(find.byType(Navigator));

    await shell.showPanel();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('desktop-panel-bar')), findsOneWidget);
    expect(find.text('Развернуть'), findsOneWidget);
    expect(find.text('Скрыть'), findsOneWidget);
    // The app below the bar is the same one, not rebuilt from scratch.
    expect(tester.state(find.byType(Navigator)), same(homeState));

    await tester.tap(find.byKey(const ValueKey('desktop-panel-hide')));
    expect(shell.calls, ['panel', 'hide']);

    await tester.tap(find.byKey(const ValueKey('desktop-panel-expand')));
    await tester.pumpAndSettle();
    expect(shell.calls, ['panel', 'hide', 'window']);
    expect(find.byKey(const ValueKey('desktop-panel-bar')), findsNothing);
    expect(home, findsOneWidget);
  });
}

class _FakeDesktopShell implements LiteriaDesktopShell {
  final _mode = ValueNotifier(LiteriaWindowMode.window);
  final calls = <String>[];

  @override
  ValueListenable<LiteriaWindowMode> get mode => _mode;

  @override
  Future<void> showPanel() async {
    calls.add('panel');
    _mode.value = LiteriaWindowMode.panel;
  }

  @override
  Future<void> showWindow() async {
    calls.add('window');
    _mode.value = LiteriaWindowMode.window;
  }

  @override
  Future<void> hide() async => calls.add('hide');

  @override
  Future<void> quit() async => calls.add('quit');

  @override
  Future<void> updateLanguage(String languageCode) async =>
      calls.add('language $languageCode');
}
