import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_reader_search.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:flutter/material.dart';

class BookReaderSearchSheet extends StatefulWidget {
  const BookReaderSearchSheet({
    required this.sections,
    required this.onSelected,
    super.key,
  });

  final List<BookSection> sections;
  final ValueChanged<BookReaderSearchResult> onSelected;

  @override
  State<BookReaderSearchSheet> createState() => _BookReaderSearchSheetState();
}

class _BookReaderSearchSheetState extends State<BookReaderSearchSheet> {
  final _queryController = TextEditingController();
  List<BookReaderSearchResult> _results = const [];

  void _search(String query) =>
      setState(() => _results = BookReaderSearch.find(widget.sections, query));

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final hasQuery = _queryController.text.trim().length >= 2;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('reader-search-field'),
                    controller: _queryController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onChanged: _search,
                    decoration: InputDecoration(
                      hintText: strings.searchInBook,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _queryController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: strings.clearSearch,
                              onPressed: () {
                                _queryController.clear();
                                _search('');
                              },
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: strings.cancel,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: !hasQuery
                ? _SearchMessage(
                    icon: Icons.manage_search,
                    text: strings.searchHint,
                  )
                : _results.isEmpty
                ? _SearchMessage(
                    icon: Icons.search_off,
                    text: strings.nothingFound,
                  )
                : ListView.separated(
                    key: const ValueKey('reader-search-results'),
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final result = _results[index];
                      return ListTile(
                        leading: const Icon(Icons.article_outlined),
                        title: Text(result.sectionTitle),
                        subtitle: Text(
                          result.excerpt,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => widget.onSelected(result),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
