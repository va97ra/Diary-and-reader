import 'dart:collection';

import 'package:dnevnik/features/books/domain/book_project.dart';

class AuthorWorkspaceSnapshot {
  AuthorWorkspaceSnapshot({
    required List<BookProject> projects,
    required this.activeProjectId,
    required this.languageCode,
  }) : _projects = List.unmodifiable(projects);

  factory AuthorWorkspaceSnapshot.fromJson(Map<String, dynamic> json) {
    final projects = (json['projects'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (project) => BookProject.fromJson(Map<String, dynamic>.from(project)),
        )
        .toList();
    final requestedActiveId = json['activeProjectId']?.toString();
    return AuthorWorkspaceSnapshot(
      projects: projects,
      activeProjectId:
          projects.any((project) => project.id == requestedActiveId)
          ? requestedActiveId
          : projects.firstOrNull?.id,
      languageCode: json['languageCode'] == 'en' ? 'en' : 'ru',
    );
  }

  static const formatVersion = 2;

  final List<BookProject> _projects;
  final String? activeProjectId;
  final String languageCode;

  UnmodifiableListView<BookProject> get projects =>
      UnmodifiableListView(_projects);

  BookProject? get activeProject =>
      _projects.where((project) => project.id == activeProjectId).firstOrNull;

  Map<String, dynamic> toJson() => {
    'formatVersion': formatVersion,
    'projects': _projects.map((project) => project.toJson()).toList(),
    'activeProjectId': activeProjectId,
    'languageCode': languageCode,
  };
}
