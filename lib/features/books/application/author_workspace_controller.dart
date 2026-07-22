import 'dart:async';
import 'dart:collection';

import 'package:dnevnik/features/books/application/manuscript_project_editor.dart';
import 'package:dnevnik/features/books/application/section_tree_editor.dart';
import 'package:dnevnik/features/books/application/transient_book_version_repository.dart';
import 'package:dnevnik/features/books/application/workspace_persistence_coordinator.dart';
import 'package:dnevnik/features/books/application/workspace_save_state.dart';
import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_snapshot.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_layout_settings.dart';
import 'package:dnevnik/features/books/domain/book_metadata.dart';
import 'package:dnevnik/features/books/domain/book_paragraph_settings.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_project_version.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_reader_progress.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_scan_folder.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/book_version_repository.dart';
import 'package:dnevnik/features/books/domain/literia_app_preferences.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:flutter/foundation.dart';

class AuthorWorkspaceController extends ChangeNotifier {
  AuthorWorkspaceController(
    AuthorWorkspaceRepository repository, {
    BookVersionRepository? versionRepository,
    Duration saveDebounce = const Duration(milliseconds: 350),
    Duration maxSaveDelay = const Duration(seconds: 2),
  }) : _versionRepository =
           versionRepository ?? TransientBookVersionRepository() {
    _persistence = WorkspacePersistenceCoordinator(
      repository,
      () => _snapshot,
      onStateChanged: notifyListeners,
      saveDebounce: saveDebounce,
      maxSaveDelay: maxSaveDelay,
    );
  }

  final BookVersionRepository _versionRepository;
  late final WorkspacePersistenceCoordinator _persistence;
  final List<BookProject> _projects = [];
  String? _activeProjectId;
  String _languageCode = 'ru';
  LiteriaAppPreferences _appPreferences = const LiteriaAppPreferences();

  UnmodifiableListView<BookProject> get projects =>
      UnmodifiableListView(_projects);
  String get languageCode => _languageCode;
  WorkspaceSaveState get saveState => _persistence.saveState;
  LiteriaAppPreferences get appPreferences => _appPreferences;
  BookReaderSettings get readerSettings => _appPreferences.readerSettings;
  LiteriaThemePreference get themePreference => _appPreferences.theme;

  BookProject? get lastManuscript => _projectById(
    _appPreferences.lastManuscriptId,
    fallback: (project) => !project.isReadOnly,
  );

  BookProject? get lastReading => _projectById(
    _appPreferences.lastReadingId,
    fallback: (project) => project.isReadOnly,
  );

  BookProject? get activeProject {
    if (_projects.isEmpty) return null;
    return _projects
            .where((project) => project.id == _activeProjectId)
            .firstOrNull ??
        _projects.first;
  }

  BookSection? get activeSection => activeProject?.activeSection;

  Future<void> load({required String preferredLanguage}) async {
    final snapshot = await _persistence.load();
    if (snapshot == null) {
      _languageCode = preferredLanguage == 'en' ? 'en' : 'ru';
      return;
    }
    _projects.addAll(snapshot.projects);
    _languageCode = snapshot.languageCode;
    _activeProjectId = snapshot.activeProjectId;
    _appPreferences = snapshot.appPreferences;
  }

  BookProject addProject() {
    final project = _newProject();
    _projects.add(project);
    _activeProjectId = project.id;
    _appPreferences = _appPreferences.copyWith(lastManuscriptId: project.id);
    _changed();
    return project;
  }

  BookProject addImportedBook(BookProject project) {
    if (project.kind != BookProjectKind.importedBook ||
        project.sections.isEmpty) {
      throw ArgumentError.value(project, 'project', 'Invalid imported book');
    }
    final id = _projects.any((candidate) => candidate.id == project.id)
        ? 'imported-${DateTime.now().microsecondsSinceEpoch}'
        : project.id;
    final imported = BookProject(
      id: id,
      metadata: project.metadata,
      sections: project.sections,
      activeSectionId: project.activeSectionId,
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
      layoutSettings: project.layoutSettings,
      paragraphSettings: project.paragraphSettings,
      readerSettings: _appPreferences.readerSettings,
      readerProgress: project.readerProgress,
      readerAnnotations: project.readerAnnotations,
      kind: BookProjectKind.importedBook,
      sourceFormat: project.sourceFormat,
      sourceFileName: project.sourceFileName,
      sourceStoredPath: project.sourceStoredPath,
      sourceFingerprint: project.sourceFingerprint,
      sourceExternalUri: project.sourceExternalUri,
      sourceFileSize: project.sourceFileSize,
      collectionName: project.collectionName,
      assets: project.assets,
      coverAssetId: project.coverAssetId,
    );
    _projects.add(imported);
    _activeProjectId = imported.id;
    _appPreferences = _appPreferences.copyWith(lastReadingId: imported.id);
    _changed();
    return imported;
  }

  void deleteProject(String id) {
    final index = _projects.indexWhere((project) => project.id == id);
    if (index < 0) return;
    _projects.removeAt(index);
    if (_activeProjectId == id) {
      _activeProjectId = _projects.isEmpty
          ? null
          : _projects[index.clamp(0, _projects.length - 1)].id;
    }
    if (_appPreferences.lastManuscriptId == id) {
      _appPreferences = _appPreferences.copyWith(clearLastManuscript: true);
    }
    if (_appPreferences.lastReadingId == id) {
      _appPreferences = _appPreferences.copyWith(clearLastReading: true);
    }
    _changed();
  }

  void updateImportedBookSource({
    required String projectId,
    required String storedPath,
    required String fingerprint,
    required String externalUri,
    required int fileSize,
  }) {
    final index = _projects.indexWhere((project) => project.id == projectId);
    if (index < 0 || !_projects[index].isReadOnly) return;
    _projects[index] = _projects[index].copyWith(
      sourceStoredPath: storedPath,
      sourceFingerprint: fingerprint,
      sourceExternalUri: externalUri,
      sourceFileSize: fileSize,
    );
    _changed();
  }

  void clearImportedBookStoredSource(String projectId) {
    final index = _projects.indexWhere((project) => project.id == projectId);
    if (index < 0 || !_projects[index].isReadOnly) return;
    _projects[index] = _projects[index].copyWith(clearStoredSource: true);
    _changed();
  }

  void addBookScanFolder(BookScanFolder folder) {
    final folders = [..._appPreferences.bookScanFolders];
    final index = folders.indexWhere((item) => item.uri == folder.uri);
    if (index >= 0) {
      folders[index] = folder;
    } else {
      folders.add(folder);
    }
    _appPreferences = _appPreferences.copyWith(bookScanFolders: folders);
    _changed();
  }

  void removeBookScanFolder(String uri) {
    final folders = _appPreferences.bookScanFolders
        .where((folder) => folder.uri != uri)
        .toList();
    if (folders.length == _appPreferences.bookScanFolders.length) return;
    _appPreferences = _appPreferences.copyWith(bookScanFolders: folders);
    _changed();
  }

  void selectProject(String id) {
    if (_activeProjectId == id) return;
    unawaited(flush());
    _activeProjectId = id;
    final selected = _projects.where((project) => project.id == id).firstOrNull;
    if (selected?.isReadOnly == true) {
      _appPreferences = _appPreferences.copyWith(lastReadingId: id);
    } else if (selected != null) {
      _appPreferences = _appPreferences.copyWith(lastManuscriptId: id);
    }
    _changed();
  }

  void updateProjectCollection(String id, String collectionName) {
    final index = _projects.indexWhere((project) => project.id == id);
    if (index < 0) return;
    final normalized = collectionName.trim();
    if (_projects[index].collectionName == normalized) return;
    _projects[index] = _projects[index].copyWith(
      collectionName: normalized,
      updatedAt: DateTime.now(),
    );
    _changed();
  }

  void selectSection(String id) {
    if (activeProject?.activeSectionId == id) return;
    unawaited(flush());
    _replaceActiveProject((project) => project.copyWith(activeSectionId: id));
    _changed();
  }

  void addSection(BookSectionType type) {
    final project = activeProject;
    if (project == null || project.isReadOnly) return;
    _replaceActiveProject(
      (current) => ManuscriptProjectEditor.addSection(
        current,
        type,
        languageCode: _languageCode,
      ),
    );
    _changed();
  }

  void moveSection(String id, TreeMoveDirection direction) {
    if (activeProject?.isReadOnly ?? true) return;
    _replaceActiveProject(
      (project) => ManuscriptProjectEditor.moveSection(project, id, direction),
    );
    _changed();
  }

  void deleteSection(String id) {
    final project = activeProject;
    if (project == null || project.isReadOnly) return;
    _replaceActiveProject(
      (current) => ManuscriptProjectEditor.deleteSection(
        current,
        id,
        languageCode: _languageCode,
      ),
    );
    _changed();
  }

  void updateSectionTitle(String title) {
    if (activeProject?.isReadOnly ?? true) return;
    _replaceActiveProject(
      (project) => ManuscriptProjectEditor.updateSectionTitle(project, title),
    );
    _changed();
  }

  void updateSectionContent(RichDocument content) {
    if (activeProject?.isReadOnly ?? true) return;
    _replaceActiveProject(
      (project) =>
          ManuscriptProjectEditor.updateSectionContent(project, content),
    );
    _markDirty();
    notifyListeners();
    _persistence.scheduleSave();
  }

  void addAsset(BookAsset asset) {
    final project = activeProject;
    if (project == null || project.isReadOnly || !asset.isRenderableImage) {
      return;
    }
    _replaceActiveProject(
      (current) => ManuscriptProjectEditor.addAsset(current, asset),
    );
    _changed();
  }

  int replaceAllInManuscript(
    String query,
    String replacement, {
    bool caseSensitive = false,
  }) {
    final project = activeProject;
    if (project == null || project.isReadOnly || query.isEmpty) return 0;
    final result = ManuscriptProjectEditor.replaceAll(
      project,
      query,
      replacement,
      caseSensitive: caseSensitive,
    );
    if (result.count == 0) return 0;
    _replaceActiveProject((_) => result.project);
    _changed();
    return result.count;
  }

  void updateSectionStatus(DraftStatus status) {
    if (activeProject?.isReadOnly ?? true) return;
    _replaceActiveProject(
      (project) => ManuscriptProjectEditor.updateSectionStatus(project, status),
    );
    _changed();
  }

  void updateSectionTargetWords(int targetWords) {
    if (activeProject?.isReadOnly ?? true) return;
    _replaceActiveProject(
      (project) => ManuscriptProjectEditor.updateSectionTargetWords(
        project,
        targetWords,
      ),
    );
    _changed();
  }

  void updateMetadata(BookMetadata metadata) {
    if (activeProject?.isReadOnly ?? true) return;
    _replaceActiveProject(
      (project) => ManuscriptProjectEditor.updateMetadata(project, metadata),
    );
    _changed();
  }

  void updateLayoutSettings(BookLayoutSettings layoutSettings) {
    if (activeProject?.isReadOnly ?? true) return;
    _replaceActiveProject(
      (project) =>
          ManuscriptProjectEditor.updateLayoutSettings(project, layoutSettings),
    );
    _changed();
  }

  void updateParagraphSettings(BookParagraphSettings paragraphSettings) {
    if (activeProject?.isReadOnly ?? true) return;
    _replaceActiveProject(
      (project) => ManuscriptProjectEditor.updateParagraphSettings(
        project,
        paragraphSettings,
      ),
    );
    _changed();
  }

  void updateReaderSettings(BookReaderSettings readerSettings) {
    _appPreferences = _appPreferences.copyWith(readerSettings: readerSettings);
    for (var index = 0; index < _projects.length; index++) {
      _projects[index] = _projects[index].copyWith(
        readerSettings: readerSettings,
      );
    }
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

  void setThemePreference(LiteriaThemePreference preference) {
    if (_appPreferences.theme == preference) return;
    _appPreferences = _appPreferences.copyWith(theme: preference);
    _changed();
  }

  void markOnboardingSeen() {
    if (_appPreferences.onboardingSeen) return;
    _appPreferences = _appPreferences.copyWith(onboardingSeen: true);
    _changed();
  }

  void resetOnboarding() {
    if (!_appPreferences.onboardingSeen) return;
    _appPreferences = _appPreferences.copyWith(onboardingSeen: false);
    _changed();
  }

  Future<List<BookProjectVersion>> listVersions() async {
    final project = activeProject;
    if (project == null || project.isReadOnly) return const [];
    return _versionRepository.list(project.id);
  }

  Future<BookProjectVersion?> createVersion({String? label}) async {
    await flush();
    final project = activeProject;
    if (project == null || project.isReadOnly) return null;
    return _versionRepository.create(project: project, label: label);
  }

  Future<void> deleteVersion(String versionId) async {
    final project = activeProject;
    if (project == null || project.isReadOnly) return;
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
    if (current == null ||
        current.isReadOnly ||
        version.projectId != current.id) {
      return;
    }
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

  Future<void> flush() => _persistence.flush();

  Future<void> _replaceActiveProjectFromExternalSource(
    BookProject source, {
    required String safetyLabel,
  }) async {
    await flush();
    final current = activeProject;
    if (current == null || current.isReadOnly || source.sections.isEmpty) {
      return;
    }
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
      kind: current.kind,
      sourceFormat: current.sourceFormat,
      sourceFileName: current.sourceFileName,
      sourceStoredPath: current.sourceStoredPath,
      sourceFingerprint: current.sourceFingerprint,
      sourceExternalUri: current.sourceExternalUri,
      sourceFileSize: current.sourceFileSize,
      collectionName: current.collectionName,
      assets: current.assets,
      coverAssetId: current.coverAssetId,
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
  ).copyWith(readerSettings: _appPreferences.readerSettings);

  void _replaceActiveProject(BookProject Function(BookProject project) update) {
    final index = _projects.indexWhere(
      (project) => project.id == activeProject?.id,
    );
    if (index >= 0) _projects[index] = update(_projects[index]);
  }

  BookProject? _projectById(
    String? id, {
    required bool Function(BookProject project) fallback,
  }) {
    final requested = _projects
        .where((project) => project.id == id)
        .firstOrNull;
    if (requested != null && fallback(requested)) return requested;
    final candidates = _projects.where(fallback).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return candidates.firstOrNull;
  }

  void _changed() {
    _markDirty();
    notifyListeners();
    _persistence.scheduleSave();
  }

  void _markDirty() => _persistence.markChanged();

  AuthorWorkspaceSnapshot get _snapshot => AuthorWorkspaceSnapshot(
    projects: List.unmodifiable(_projects),
    activeProjectId: _activeProjectId,
    languageCode: _languageCode,
    appPreferences: _appPreferences,
  );

  @override
  void dispose() {
    _persistence.dispose();
    super.dispose();
  }
}
