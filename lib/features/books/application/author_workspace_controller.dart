import 'dart:async';
import 'dart:collection';

import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter/foundation.dart';

class AuthorWorkspaceController extends ChangeNotifier {
  AuthorWorkspaceController(this._repository);

  final AuthorWorkspaceRepository _repository;
  final List<BookProject> _projects = [];
  Timer? _saveTimer;
  String? _activeProjectId;
  String _languageCode = 'ru';

  UnmodifiableListView<BookProject> get projects =>
      UnmodifiableListView(_projects);
  String get languageCode => _languageCode;

  BookProject? get activeProject {
    if (_projects.isEmpty) return null;
    return _projects
            .where((project) => project.id == _activeProjectId)
            .firstOrNull ??
        _projects.first;
  }

  BookSection? get activeSection => activeProject?.activeSection;

  Future<void> load({required String preferredLanguage}) async {
    final snapshot = await _repository.load();
    if (snapshot == null || snapshot.projects.isEmpty) {
      _languageCode = preferredLanguage == 'en' ? 'en' : 'ru';
      final project = _newProject();
      _projects.add(project);
      _activeProjectId = project.id;
      await flush();
      return;
    }
    _projects.addAll(snapshot.projects);
    _languageCode = snapshot.languageCode;
    _activeProjectId = snapshot.activeProjectId;
  }

  void addProject() {
    final project = _newProject();
    _projects.add(project);
    _activeProjectId = project.id;
    _changed();
  }

  void selectProject(String id) {
    if (_activeProjectId == id) return;
    _activeProjectId = id;
    _changed();
  }

  void selectSection(String id) {
    _replaceActiveProject((project) => project.copyWith(activeSectionId: id));
    _changed();
  }

  void addSection(BookSectionType type) {
    final project = activeProject;
    if (project == null) return;
    final parentId = _parentForNewSection(project, type);
    final section = BookSection.create(
      title: _defaultSectionTitle(type),
      type: type,
      parentId: parentId,
    );
    _replaceActiveProject(
      (current) => current.copyWith(
        sections: [...current.sections, section],
        activeSectionId: section.id,
        updatedAt: DateTime.now(),
      ),
    );
    _changed();
  }

  void updateSectionTitle(String title) {
    _updateActiveSection((section) => section.copyWith(title: title));
    _changed();
  }

  void updateSectionContent(RichDocument content) {
    _updateActiveSection(
      (section) =>
          section.copyWith(content: content, updatedAt: DateTime.now()),
    );
    notifyListeners();
    _scheduleSave();
  }

  void updateSectionStatus(DraftStatus status) {
    _updateActiveSection(
      (section) => section.copyWith(status: status, updatedAt: DateTime.now()),
    );
    _changed();
  }

  void updateMetadata(BookMetadata metadata) {
    _replaceActiveProject(
      (project) =>
          project.copyWith(metadata: metadata, updatedAt: DateTime.now()),
    );
    _changed();
  }

  void setLanguage(String languageCode) {
    _languageCode = languageCode == 'en' ? 'en' : 'ru';
    _changed();
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    await _repository.save(_snapshot);
  }

  BookProject _newProject() => BookProject.create(
    title: _languageCode == 'en' ? 'Untitled book' : 'Новая книга',
    chapterTitle: _languageCode == 'en' ? 'Chapter 1' : 'Глава 1',
    languageCode: _languageCode,
  );

  String _defaultSectionTitle(BookSectionType type) => switch (type) {
    BookSectionType.part => _languageCode == 'en' ? 'New part' : 'Новая часть',
    BookSectionType.chapter =>
      _languageCode == 'en' ? 'New chapter' : 'Новая глава',
    BookSectionType.scene =>
      _languageCode == 'en' ? 'New scene' : 'Новая сцена',
  };

  String? _parentForNewSection(BookProject project, BookSectionType type) {
    final active = project.activeSection;
    if (active == null || type == BookSectionType.part) return null;
    if (type == BookSectionType.chapter) {
      return active.type == BookSectionType.part ? active.id : active.parentId;
    }
    if (active.type == BookSectionType.chapter) return active.id;
    return active.type == BookSectionType.scene ? active.parentId : null;
  }

  void _updateActiveSection(BookSection Function(BookSection section) update) {
    final activeId = activeProject?.activeSectionId;
    if (activeId == null) return;
    _replaceActiveProject((project) {
      final sections = project.sections
          .map((section) => section.id == activeId ? update(section) : section)
          .toList();
      return project.copyWith(sections: sections, updatedAt: DateTime.now());
    });
  }

  void _replaceActiveProject(BookProject Function(BookProject project) update) {
    final index = _projects.indexWhere(
      (project) => project.id == activeProject?.id,
    );
    if (index >= 0) _projects[index] = update(_projects[index]);
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

  AuthorWorkspaceSnapshot get _snapshot => AuthorWorkspaceSnapshot(
    projects: List.unmodifiable(_projects),
    activeProjectId: _activeProjectId,
    languageCode: _languageCode,
  );

  @override
  void dispose() {
    _saveTimer?.cancel();
    unawaited(_repository.save(_snapshot));
    super.dispose();
  }
}
