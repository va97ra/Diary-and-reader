import 'dart:async';
import 'dart:collection';

import 'package:dnevnik/features/books/application/section_tree_editor.dart';
import 'package:dnevnik/features/books/application/workspace_save_state.dart';
import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_project_version.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/book_version_repository.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter/foundation.dart';

class AuthorWorkspaceController extends ChangeNotifier {
  AuthorWorkspaceController(
    this._repository, {
    BookVersionRepository? versionRepository,
  }) : _versionRepository =
           versionRepository ?? _TransientBookVersionRepository();

  final AuthorWorkspaceRepository _repository;
  final BookVersionRepository _versionRepository;
  final List<BookProject> _projects = [];
  Future<void> _saveQueue = Future.value();
  Timer? _saveTimer;
  String? _activeProjectId;
  String _languageCode = 'ru';
  WorkspaceSaveState _saveState = WorkspaceSaveState.saved;
  int _changeRevision = 0;
  bool _isDisposed = false;

  UnmodifiableListView<BookProject> get projects =>
      UnmodifiableListView(_projects);
  String get languageCode => _languageCode;
  WorkspaceSaveState get saveState => _saveState;

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

  void deleteProject(String id) {
    final index = _projects.indexWhere((project) => project.id == id);
    if (index < 0) return;
    _projects.removeAt(index);
    if (_projects.isEmpty) _projects.add(_newProject());
    if (_activeProjectId == id) {
      _activeProjectId = _projects[index.clamp(0, _projects.length - 1)].id;
    }
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
        sections: SectionTreeEditor.insertAtEndOfParent(
          current.sections,
          section,
        ),
        activeSectionId: section.id,
        updatedAt: DateTime.now(),
      ),
    );
    _changed();
  }

  void moveSection(String id, TreeMoveDirection direction) {
    _replaceActiveProject(
      (project) => project.copyWith(
        sections: SectionTreeEditor.moveSubtree(
          project.sections,
          id,
          direction,
        ),
        updatedAt: DateTime.now(),
      ),
    );
    _changed();
  }

  void deleteSection(String id) {
    final project = activeProject;
    if (project == null) return;
    var sections = SectionTreeEditor.removeSubtree(project.sections, id);
    if (sections.isEmpty) {
      sections = [
        BookSection.create(
          title: _languageCode == 'en' ? 'Chapter 1' : 'Глава 1',
          type: BookSectionType.chapter,
        ),
      ];
    }
    final activeStillExists = sections.any(
      (section) => section.id == project.activeSectionId,
    );
    _replaceActiveProject((current) {
      final sectionIds = sections.map((section) => section.id).toSet();
      final readerSectionExists = sectionIds.contains(
        current.readerProgress.sectionId,
      );
      return current.copyWith(
        sections: sections,
        activeSectionId: activeStillExists
            ? current.activeSectionId
            : sections.first.id,
        readerProgress: readerSectionExists
            ? current.readerProgress
            : BookReaderProgress(sectionId: sections.first.id),
        readerAnnotations: current.readerAnnotations.retainSections(sectionIds),
        updatedAt: DateTime.now(),
      );
    });
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
    _markDirty();
    notifyListeners();
    _scheduleSave();
  }

  void updateSectionStatus(DraftStatus status) {
    _updateActiveSection(
      (section) => section.copyWith(status: status, updatedAt: DateTime.now()),
    );
    _changed();
  }

  void updateSectionTargetWords(int targetWords) {
    _updateActiveSection(
      (section) =>
          section.copyWith(targetWords: targetWords, updatedAt: DateTime.now()),
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

  void updateLayoutSettings(BookLayoutSettings layoutSettings) {
    _replaceActiveProject(
      (project) => project.copyWith(
        layoutSettings: layoutSettings,
        updatedAt: DateTime.now(),
      ),
    );
    _changed();
  }

  void updateParagraphSettings(BookParagraphSettings paragraphSettings) {
    _replaceActiveProject(
      (project) => project.copyWith(
        paragraphSettings: paragraphSettings,
        updatedAt: DateTime.now(),
      ),
    );
    _changed();
  }

  void updateReaderSettings(BookReaderSettings readerSettings) {
    _replaceActiveProject(
      (project) => project.copyWith(
        readerSettings: readerSettings,
        updatedAt: DateTime.now(),
      ),
    );
    _changed();
  }

  void updateReaderProgress(BookReaderProgress readerProgress) {
    _replaceActiveProject(
      (project) => project.copyWith(
        readerProgress: readerProgress,
        updatedAt: DateTime.now(),
      ),
    );
    _changed();
  }

  void updateReaderAnnotations(BookReaderAnnotations readerAnnotations) {
    _replaceActiveProject(
      (project) => project.copyWith(
        readerAnnotations: readerAnnotations,
        updatedAt: DateTime.now(),
      ),
    );
    _changed();
  }

  void setLanguage(String languageCode) {
    _languageCode = languageCode == 'en' ? 'en' : 'ru';
    _changed();
  }

  Future<List<BookProjectVersion>> listVersions() async {
    final project = activeProject;
    if (project == null) return const [];
    return _versionRepository.list(project.id);
  }

  Future<BookProjectVersion?> createVersion({String? label}) async {
    await flush();
    final project = activeProject;
    if (project == null) return null;
    return _versionRepository.create(project: project, label: label);
  }

  Future<void> deleteVersion(String versionId) async {
    final project = activeProject;
    if (project == null) return;
    await _versionRepository.delete(
      projectId: project.id,
      versionId: versionId,
    );
  }

  Future<void> restoreVersion(
    BookProjectVersion version, {
    required String safetyLabel,
  }) async {
    final current = activeProject;
    if (current == null || version.projectId != current.id) return;
    await _replaceActiveProjectFromExternalSource(
      version.project,
      safetyLabel: safetyLabel,
    );
  }

  Future<void> importProject(
    BookProject project, {
    required String safetyLabel,
  }) => _replaceActiveProjectFromExternalSource(
    project,
    safetyLabel: safetyLabel,
  );

  Future<void> flush() async {
    _saveTimer?.cancel();
    final revision = _changeRevision;
    final snapshot = _snapshot;
    try {
      await _enqueueSave(snapshot);
      if (_isDisposed || revision != _changeRevision) return;
      _setSaveState(WorkspaceSaveState.saved);
    } catch (_) {
      if (_isDisposed || revision != _changeRevision) return;
      _setSaveState(WorkspaceSaveState.error);
    }
  }

  Future<void> _replaceActiveProjectFromExternalSource(
    BookProject source, {
    required String safetyLabel,
  }) async {
    await flush();
    final current = activeProject;
    if (current == null || source.sections.isEmpty) return;
    await _versionRepository.create(project: current, label: safetyLabel);
    final index = _projects.indexWhere((project) => project.id == current.id);
    if (index < 0) return;
    final copied = BookProject.fromJson(source.toJson());
    _projects[index] = BookProject(
      id: current.id,
      metadata: copied.metadata,
      sections: copied.sections,
      activeSectionId: copied.activeSectionId,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
      layoutSettings: copied.layoutSettings,
      paragraphSettings: copied.paragraphSettings,
      readerSettings: copied.readerSettings,
      readerProgress: copied.readerProgress,
      readerAnnotations: copied.readerAnnotations,
    );
    _activeProjectId = current.id;
    _markDirty();
    notifyListeners();
    await flush();
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
      if (active.type == BookSectionType.part) return active.id;
      if (active.type == BookSectionType.chapter) return active.parentId;
      final parentChapter = project.sections
          .where((section) => section.id == active.parentId)
          .firstOrNull;
      return parentChapter?.parentId;
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
    _markDirty();
    notifyListeners();
    _scheduleSave();
  }

  void _markDirty() {
    _changeRevision++;
    _saveState = WorkspaceSaveState.saving;
  }

  void _setSaveState(WorkspaceSaveState state) {
    if (_saveState == state) return;
    _saveState = state;
    notifyListeners();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(flush()),
    );
  }

  Future<void> _enqueueSave(AuthorWorkspaceSnapshot snapshot) {
    final save = _saveQueue.then((_) => _repository.save(snapshot));
    _saveQueue = save.catchError((_) {});
    return save;
  }

  AuthorWorkspaceSnapshot get _snapshot => AuthorWorkspaceSnapshot(
    projects: List.unmodifiable(_projects),
    activeProjectId: _activeProjectId,
    languageCode: _languageCode,
  );

  @override
  void dispose() {
    _isDisposed = true;
    _saveTimer?.cancel();
    unawaited(_enqueueSave(_snapshot).catchError((_) {}));
    super.dispose();
  }
}

class _TransientBookVersionRepository implements BookVersionRepository {
  final List<BookProjectVersion> _versions = [];

  @override
  Future<List<BookProjectVersion>> list(String projectId) async {
    final versions =
        _versions.where((version) => version.projectId == projectId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return versions;
  }

  @override
  Future<BookProjectVersion> create({
    required BookProject project,
    String? label,
  }) async {
    final now = DateTime.now().toUtc();
    final normalizedLabel = label?.trim();
    final version = BookProjectVersion(
      id: 'version-${now.microsecondsSinceEpoch}',
      projectId: project.id,
      createdAt: now,
      label: normalizedLabel == null || normalizedLabel.isEmpty
          ? null
          : normalizedLabel,
      project: BookProject.fromJson(project.toJson()),
    );
    _versions.add(version);
    return version;
  }

  @override
  Future<void> delete({
    required String projectId,
    required String versionId,
  }) async {
    _versions.removeWhere(
      (version) => version.projectId == projectId && version.id == versionId,
    );
  }
}
