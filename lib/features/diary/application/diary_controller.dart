import 'dart:async';
import 'dart:collection';

import 'package:dnevnik/features/diary/application/diary_archive_codec.dart';
import 'package:dnevnik/features/diary/application/page_paginator.dart';
import 'package:dnevnik/features/diary/domain/diary_entry.dart';
import 'package:dnevnik/features/diary/domain/diary_repository.dart';
import 'package:dnevnik/features/diary/domain/diary_snapshot.dart';
import 'package:dnevnik/features/diary/domain/page_margins.dart';
import 'package:flutter/foundation.dart';

class DiaryController extends ChangeNotifier {
  DiaryController(this._repository);

  final DiaryRepository _repository;
  final List<DiaryEntry> _entries = [];
  Timer? _saveTimer;
  String? _activeEntryId;
  String _languageCode = 'ru';
  PageMargins _margins = const PageMargins.normal();

  UnmodifiableListView<DiaryEntry> get entries =>
      UnmodifiableListView(_entries);
  String get languageCode => _languageCode;
  PageMargins get margins => _margins;

  DiaryEntry? get activeEntry {
    if (_entries.isEmpty) return null;
    final index = _entries.indexWhere((entry) => entry.id == _activeEntryId);
    return index >= 0 ? _entries[index] : _entries.first;
  }

  Future<void> load({required String preferredLanguage}) async {
    final snapshot = await _repository.load();
    if (snapshot == null) {
      _languageCode = preferredLanguage == 'en' ? 'en' : 'ru';
      final entry = DiaryEntry.create(
        title: _languageCode == 'en' ? 'New entry' : 'Новая запись',
      );
      _entries.add(entry);
      _activeEntryId = entry.id;
      await flush();
      return;
    }
    _entries.addAll(snapshot.entries);
    _languageCode = snapshot.languageCode;
    _margins = snapshot.margins;
    _activeEntryId = snapshot.activeEntryId;
    if (_entries.isEmpty) {
      addEntry(_languageCode == 'en' ? 'New entry' : 'Новая запись');
    }
  }

  void addEntry(String title) {
    final entry = DiaryEntry.create(title: title);
    _entries.insert(0, entry);
    _activeEntryId = entry.id;
    _changed();
  }

  void selectEntry(String id) {
    if (_activeEntryId == id) return;
    _activeEntryId = id;
    _changed();
  }

  void deleteEntry(String id, {required String fallbackTitle}) {
    _entries.removeWhere((entry) => entry.id == id);
    if (_entries.isEmpty) {
      _entries.add(DiaryEntry.create(title: fallbackTitle));
    }
    if (_activeEntryId == id) _activeEntryId = _entries.first.id;
    _changed();
  }

  void updateTitle(String id, String title) {
    _replaceEntry(id, (entry) => entry.copyWith(title: title));
    _changed();
  }

  void updatePage(String id, int pageIndex, PageDocument document) {
    _replaceEntry(id, (entry) {
      if (pageIndex >= entry.pages.length) return entry;
      final pages = [...entry.pages]..[pageIndex] = document;
      return entry.copyWith(pages: pages);
    });
    _scheduleSave();
  }

  void addPage(String id) {
    _replaceEntry(
      id,
      (entry) =>
          entry.copyWith(pages: [...entry.pages, DiaryEntry.emptyPage()]),
    );
    _changed();
  }

  void paginatePage(String id, int pageIndex, int splitOffset) {
    _replaceEntry(id, (entry) {
      if (pageIndex >= entry.pages.length) return entry;
      final split = PagePaginator.split(entry.pages[pageIndex], splitOffset);
      final pages = [...entry.pages]..[pageIndex] = split.visible;
      final nextIndex = pageIndex + 1;
      if (nextIndex < pages.length) {
        pages[nextIndex] = PagePaginator.prependOverflow(
          split.overflow,
          pages[nextIndex],
        );
      } else {
        pages.add(split.overflow);
      }
      return entry.copyWith(pages: pages);
    });
    _changed();
  }

  void setLanguage(String languageCode) {
    _languageCode = languageCode == 'en' ? 'en' : 'ru';
    _changed();
  }

  void setMargins(PageMargins margins) {
    _margins = margins;
    _changed();
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    await _repository.save(_snapshot);
  }

  String exportArchive() => DiaryArchiveCodec.encode(_snapshot);

  Future<void> importArchive(String encoded) async {
    final imported = DiaryArchiveCodec.decode(encoded);
    _entries
      ..clear()
      ..addAll(imported.entries);
    _languageCode = imported.languageCode;
    _margins = imported.margins;
    _activeEntryId = imported.activeEntryId;
    if (_entries.isEmpty) {
      final title = _languageCode == 'en' ? 'New entry' : 'Новая запись';
      _entries.add(DiaryEntry.create(title: title));
    }
    final activeExists = _entries.any((entry) => entry.id == _activeEntryId);
    if (!activeExists) _activeEntryId = _entries.first.id;
    notifyListeners();
    await flush();
  }

  void _replaceEntry(String id, DiaryEntry Function(DiaryEntry entry) update) {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index >= 0) _entries[index] = update(_entries[index]);
  }

  void _changed() {
    notifyListeners();
    _scheduleSave();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(flush()),
    );
  }

  DiarySnapshot get _snapshot => DiarySnapshot(
    entries: List.unmodifiable(_entries),
    activeEntryId: _activeEntryId,
    languageCode: _languageCode,
    margins: _margins,
  );

  @override
  void dispose() {
    _saveTimer?.cancel();
    unawaited(_repository.save(_snapshot));
    super.dispose();
  }
}
