import 'dart:convert';

import 'package:dnevnik/features/books/application/book_deleted_text.dart';
import 'package:dnevnik/features/books/application/manuscript_project_editor.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter_test/flutter_test.dart';

const _picture = {
  'bookImage': {'assetId': 'picture', 'alignment': 'center', 'width': 100},
};

RichDocument _text(String value) => [
  {'insert': value},
];

void main() {
  group('BookDeletedText', () {
    test('keeps a deleted word with its formatting and place', () {
      final deleted = BookDeletedText.between([
        {'insert': 'Мороз и '},
        {
          'insert': 'солнце',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ], _text('Мороз и \n'));

      expect(deleted?.offset, 8);
      expect(deleted?.content, [
        {
          'insert': 'солнце',
          'attributes': {'bold': true},
        },
      ]);
    });

    test('ignores an erased letter, a typo fix and part of a word', () {
      expect(
        BookDeletedText.between(_text('солнце\n'), _text('солнц\n')),
        isNull,
      );
      expect(
        BookDeletedText.between(_text('тихй день\n'), _text('тихий день\n')),
        isNull,
      );
      expect(
        BookDeletedText.between(_text('солнце\n'), _text('сол\n')),
        isNull,
      );
    });

    test('keeps a deleted picture', () {
      final deleted = BookDeletedText.between([
        {'insert': 'Текст\n'},
        {'insert': _picture},
        {'insert': '\n'},
      ], _text('Текст\n'));

      expect(deleted?.content.first['insert'], _picture);
    });

    test('keeps what a replacement took out, not what it put in', () {
      final deleted = BookDeletedText.between(
        _text('Утро туманное, утро седое\n'),
        _text('Утро ясное\n'),
      );

      expect(richDocumentPlainText(deleted!.content), 'туманное, утро седое');
    });

    test('puts a fragment back where it was, or at the end', () {
      final fragment = [
        {'insert': 'солнце'},
      ];
      expect(
        richDocumentPlainText(
          BookDeletedText.restore(_text('Мороз и \n'), 8, fragment),
        ),
        'Мороз и солнце\n',
      );
      expect(
        richDocumentPlainText(
          BookDeletedText.restore(_text('Мороз\n'), 40, fragment),
        ),
        'Мороз солнце\n',
      );
      expect(
        richDocumentPlainText(
          BookDeletedText.restore(_text('Утро ясное\n'), 5, [
            {'insert': 'туманное, утро седое'},
          ]),
        ),
        'Утро туманное, утро седое ясное\n',
      );
    });
  });

  group('text trash', () {
    BookProject book(String text) {
      final project = BookProject.create(title: 'Книга', chapterTitle: 'Глава');
      return project.copyWith(
        sections: [project.sections.single.copyWith(content: _text('$text\n'))],
      );
    }

    test(
      'an edit that deletes words fills the trash, a restore empties it',
      () {
        final edited = ManuscriptProjectEditor.updateSectionContent(
          book('Мороз и солнце, день чудесный'),
          _text('Мороз и солнце\n'),
        );

        expect(edited.textTrash, hasLength(1));
        final entry = edited.textTrash.single;
        expect(richDocumentPlainText(entry.content), ', день чудесный');

        final saved = BookProject.fromJson(
          jsonDecode(jsonEncode(edited.toJson())) as Map<String, dynamic>,
        );
        expect(saved.textTrash.single.content, entry.content);

        final restored = ManuscriptProjectEditor.restoreDeletedText(
          saved,
          entry.id,
        );
        expect(restored.textTrash, isEmpty);
        expect(
          richDocumentPlainText(restored.sections.single.content),
          'Мороз и солнце, день чудесный\n',
        );
      },
    );

    test('the trash keeps only the newest fragments', () {
      var project = book('');
      for (
        var index = 0;
        index <= ManuscriptProjectEditor.textTrashLimit;
        index++
      ) {
        project = ManuscriptProjectEditor.updateSectionContent(
          project,
          _text('слово$index слово\n'),
        );
        project = ManuscriptProjectEditor.updateSectionContent(
          project,
          _text('\n'),
        );
      }

      expect(
        project.textTrash,
        hasLength(ManuscriptProjectEditor.textTrashLimit),
      );
      expect(
        richDocumentPlainText(project.textTrash.last.content),
        contains('слово${ManuscriptProjectEditor.textTrashLimit}'),
      );
    });
  });
}
