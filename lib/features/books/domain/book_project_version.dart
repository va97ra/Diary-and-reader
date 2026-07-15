import 'package:dnevnik/features/books/domain/book_project.dart';

class BookProjectVersion {
  BookProjectVersion({
    required this.id,
    required this.projectId,
    required this.createdAt,
    required this.project,
    this.label,
  });

  factory BookProjectVersion.fromJson(Map<String, dynamic> json) {
    final projectJson = json['project'];
    if (projectJson is! Map) {
      throw const FormatException('A book version has no project data.');
    }
    final project = BookProject.fromJson(
      Map<String, dynamic>.from(projectJson),
    );
    final id = json['id']?.toString().trim() ?? '';
    final projectId = json['projectId']?.toString().trim() ?? '';
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    if (id.isEmpty || projectId.isEmpty || createdAt == null) {
      throw const FormatException('Invalid book version metadata.');
    }
    final label = json['label']?.toString().trim();
    return BookProjectVersion(
      id: id,
      projectId: projectId,
      createdAt: createdAt,
      project: project,
      label: label == null || label.isEmpty ? null : label,
    );
  }

  final String id;
  final String projectId;
  final DateTime createdAt;
  final String? label;
  final BookProject project;

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'label': label,
    'project': project.toJson(),
  };
}
