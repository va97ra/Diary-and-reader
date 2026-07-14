import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_contents.dart';
import 'package:flutter/material.dart';

typedef BookReaderLocationCallback =
    void Function(String sectionId, double sectionProgress);

class BookReaderNavigationPanel extends StatelessWidget {
  const BookReaderNavigationPanel({
    required this.sections,
    required this.activeSectionId,
    required this.annotations,
    required this.onLocationSelected,
    required this.onAddNote,
    required this.onEditNote,
    required this.onDeleteBookmark,
    required this.onDeleteNote,
    super.key,
  });

  final List<BookSection> sections;
  final String activeSectionId;
  final BookReaderAnnotations annotations;
  final BookReaderLocationCallback onLocationSelected;
  final VoidCallback onAddNote;
  final ValueChanged<BookReaderNote> onEditNote;
  final ValueChanged<BookReaderBookmark> onDeleteBookmark;
  final ValueChanged<BookReaderNote> onDeleteNote;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: strings.contentsShort, icon: const Icon(Icons.toc)),
              Tab(
                text: strings.bookmarks,
                icon: const Icon(Icons.bookmarks_outlined),
              ),
              Tab(
                text: strings.notes,
                icon: const Icon(Icons.sticky_note_2_outlined),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                BookReaderContents(
                  sections: sections,
                  activeSectionId: activeSectionId,
                  onSelected: (section) => onLocationSelected(section.id, 0),
                ),
                _BookmarksList(
                  bookmarks: annotations.bookmarks,
                  sections: sections,
                  onSelected: onLocationSelected,
                  onDelete: onDeleteBookmark,
                ),
                _NotesList(
                  notes: annotations.notes,
                  sections: sections,
                  onSelected: onLocationSelected,
                  onAdd: onAddNote,
                  onEdit: onEditNote,
                  onDelete: onDeleteNote,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarksList extends StatelessWidget {
  const _BookmarksList({
    required this.bookmarks,
    required this.sections,
    required this.onSelected,
    required this.onDelete,
  });

  final List<BookReaderBookmark> bookmarks;
  final List<BookSection> sections;
  final BookReaderLocationCallback onSelected;
  final ValueChanged<BookReaderBookmark> onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    if (bookmarks.isEmpty) {
      return _EmptyReaderList(
        icon: Icons.bookmark_add_outlined,
        message: strings.noBookmarks,
      );
    }
    return ListView.builder(
      key: const ValueKey('reader-bookmarks'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return ListTile(
          title: Text(
            bookmark.excerpt.isEmpty ? strings.bookmark : bookmark.excerpt,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _locationLabel(
              sections,
              bookmark.sectionId,
              bookmark.sectionProgress,
            ),
          ),
          trailing: IconButton(
            tooltip: strings.deleteBookmark,
            onPressed: () => onDelete(bookmark),
            icon: const Icon(Icons.delete_outline),
          ),
          onTap: () => onSelected(bookmark.sectionId, bookmark.sectionProgress),
        );
      },
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({
    required this.notes,
    required this.sections,
    required this.onSelected,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<BookReaderNote> notes;
  final List<BookSection> sections;
  final BookReaderLocationCallback onSelected;
  final VoidCallback onAdd;
  final ValueChanged<BookReaderNote> onEdit;
  final ValueChanged<BookReaderNote> onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      children: [
        Expanded(
          child: notes.isEmpty
              ? _EmptyReaderList(
                  icon: Icons.note_add_outlined,
                  message: strings.noNotes,
                )
              : ListView.builder(
                  key: const ValueKey('reader-notes'),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return ListTile(
                      title: Text(
                        note.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _locationLabel(
                          sections,
                          note.sectionId,
                          note.sectionProgress,
                        ),
                      ),
                      trailing: PopupMenuButton<_NoteAction>(
                        onSelected: (action) => switch (action) {
                          _NoteAction.edit => onEdit(note),
                          _NoteAction.delete => onDelete(note),
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: _NoteAction.edit,
                            child: Text(strings.editNote),
                          ),
                          PopupMenuItem(
                            value: _NoteAction.delete,
                            child: Text(strings.deleteNote),
                          ),
                        ],
                      ),
                      onTap: () =>
                          onSelected(note.sectionId, note.sectionProgress),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('reader-add-note'),
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: Text(strings.addNoteHere),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyReaderList extends StatelessWidget {
  const _EmptyReaderList({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

String _locationLabel(
  List<BookSection> sections,
  String sectionId,
  double progress,
) {
  final title = sections
      .where((section) => section.id == sectionId)
      .firstOrNull
      ?.title;
  return '${title ?? '—'} · ${(progress * 100).round()}%';
}

enum _NoteAction { edit, delete }
