import 'dart:collection';

import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/literia_app_preferences.dart';

class AuthorWorkspaceSnapshot {
  AuthorWorkspaceSnapshot({
    required List<BookProject> projects,
    required this.activeProjectId,
    required this.languageCode,
    this.appPreferences = const LiteriaAppPreferences(),
  }) : _projects = List.unmodifiable(projects);

  factory AuthorWorkspaceSnapshot.fromJson(Map<String, dynamic> json) {
    final projects = (json['projects'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (project) => BookProject.fromJson(Map<String, dynamic>.from(project)),
        )
        .toList();
    final requestedActiveId = json['activeProjectId']?.toString();
    final preferences = json['appPreferences'] is Map
        ? LiteriaAppPreferences.fromJson(
            Map<String, dynamic>.from(json['appPreferences'] as Map),
          )
        : _legacyPreferences(projects, requestedActiveId);
    return AuthorWorkspaceSnapshot(
      projects: projects,
      activeProjectId:
          projects.any((project) => project.id == requestedActiveId)
          ? requestedActiveId
          : projects.firstOrNull?.id,
      languageCode: json['languageCode'] == 'en' ? 'en' : 'ru',
      appPreferences: preferences,
    );
  }

  static const formatVersion = 2;

  final List<BookProject> _projects;
  final String? activeProjectId;
  final String languageCode;
  final LiteriaAppPreferences appPreferences;

  UnmodifiableListView<BookProject> get projects =>
      UnmodifiableListView(_projects);

  BookProject? get activeProject =>
      _projects.where((project) => project.id == activeProjectId).firstOrNull;

  Map<String, dynamic> toJson() => {
    'formatVersion': formatVersion,
    'projects': _projects.map((project) => project.toJson()).toList(),
    'activeProjectId': activeProjectId,
    'languageCode': languageCode,
    'appPreferences': appPreferences.toJson(),
  };
}

LiteriaAppPreferences _legacyPreferences(
  List<BookProject> projects,
  String? activeProjectId,
) {
  final active = projects
      .where((item) => item.id == activeProjectId)
      .firstOrNull;
  final manuscripts = projects.where((item) => !item.isReadOnly).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final imported = projects.where((item) => item.isReadOnly).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final readerSource = active?.isReadOnly == true
      ? active
      : imported.firstOrNull;
  return LiteriaAppPreferences(
    readerSettings: readerSource?.readerSettings ?? const BookReaderSettings(),
    lastManuscriptId: active?.isReadOnly == false
        ? active?.id
        : manuscripts.firstOrNull?.id,
    lastReadingId: active?.isReadOnly == true
        ? active?.id
        : imported.firstOrNull?.id,
  );
}
