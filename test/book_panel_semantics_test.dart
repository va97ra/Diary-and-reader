import 'package:dnevnik/features/books/presentation/widgets/book_adaptive_control_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('panel controls announce their label once and stay tappable', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              BookPanelAction(
                icon: const Icon(Icons.toc),
                label: 'Главы',
                onPressed: () => tapped.add('action'),
              ),
              LiteriaCompactActionTile(
                icon: Icons.history,
                title: 'История',
                subtitle: 'Снимки книги',
                onTap: () => tapped.add('tile'),
              ),
              BookPanelTitleAction(
                title: 'Алиса',
                label: 'Название книги',
                onPressed: () => tapped.add('title'),
              ),
              LiteriaLeatherCard(
                semanticLabel: 'Писать. Свои книги',
                onTap: () => tapped.add('card'),
                child: const Column(
                  children: [Text('Писать'), Text('Свои книги')],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    const labels = {
      'action': 'Главы',
      'tile': 'История. Снимки книги',
      'title': 'Название книги: Алиса',
      'card': 'Писать. Свои книги',
    };
    for (final MapEntry(key: control, value: label) in labels.entries) {
      // An exact label: a repeated caption would make it longer.
      final node = find.semantics.byLabel(label);
      expect(node, findsOne, reason: control);
      expect(
        node.evaluate().single,
        isSemantics(isButton: true, hasTapAction: true),
        reason: control,
      );
      tester.semantics.tap(node);
      await tester.pump();
    }
    expect(tapped, labels.keys);

    semantics.dispose();
  });
}
