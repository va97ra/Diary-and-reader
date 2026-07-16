import 'dart:math' as math;

import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/book_manuscript_search.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:flutter/material.dart';

class BookReplaceRequest {
  const BookReplaceRequest({
    required this.query,
    required this.replacement,
    required this.caseSensitive,
  });

  final String query;
  final String replacement;
  final bool caseSensitive;
}

class BookManuscriptSearchSheet extends StatefulWidget {
  const BookManuscriptSearchSheet({
    required this.project,
    required this.onOpenMatch,
    super.key,
  });

  final BookProject project;
  final ValueChanged<BookManuscriptMatch> onOpenMatch;

  @override
  State<BookManuscriptSearchSheet> createState() =>
      _BookManuscriptSearchSheetState();
}

class _BookManuscriptSearchSheetState extends State<BookManuscriptSearchSheet> {
  final _queryController = TextEditingController();
  final _replacementController = TextEditingController();
  bool _caseSensitive = false;

  @override
  void dispose() {
    _queryController.dispose();
    _replacementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final query = _queryController.text;
    final canSearch = query.trim().length >= 2;
    final matches = canSearch
        ? BookManuscriptSearch.find(
            widget.project,
            query,
            caseSensitive: _caseSensitive,
          )
        : const <BookManuscriptMatch>[];
    final height = math.min(MediaQuery.sizeOf(context).height * 0.8, 680.0);

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.findAndReplace,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('manuscript-search-field'),
                controller: _queryController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: strings.searchInBook,
                  hintText: strings.manuscriptSearchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('manuscript-replacement-field'),
                controller: _replacementController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: strings.replaceWith,
                  prefixIcon: const Icon(Icons.find_replace),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(strings.caseSensitive),
                      value: _caseSensitive,
                      onChanged: (value) =>
                          setState(() => _caseSensitive = value ?? false),
                    ),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('replace-all-button'),
                    onPressed: matches.isEmpty
                        ? null
                        : () => Navigator.pop(
                            context,
                            BookReplaceRequest(
                              query: query,
                              replacement: _replacementController.text,
                              caseSensitive: _caseSensitive,
                            ),
                          ),
                    icon: const Icon(Icons.find_replace),
                    label: Text(strings.replaceAll),
                  ),
                ],
              ),
              const Divider(),
              Text(
                canSearch
                    ? strings.matchesFound(matches.length)
                    : strings.manuscriptSearchHint,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Expanded(
                child: !canSearch
                    ? const SizedBox.shrink()
                    : matches.isEmpty
                    ? Center(child: Text(strings.nothingFound))
                    : ListView.separated(
                        key: const ValueKey('manuscript-search-results'),
                        itemCount: matches.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          return ListTile(
                            leading: const Icon(Icons.article_outlined),
                            title: Text(match.sectionTitle),
                            subtitle: Text(
                              match.excerpt,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onOpenMatch(match);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
