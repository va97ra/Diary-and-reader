import 'dart:io';

import 'package:dnevnik/features/books/data/file_author_workspace_repository.dart';
import 'package:dnevnik/features/books/data/preferences_author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AuthorWorkspaceRepository> createAuthorWorkspaceRepository(
  SharedPreferences preferences,
) async {
  final supportDirectory = await getApplicationSupportDirectory();
  final workspaceDirectory = Directory(
    '${supportDirectory.path}${Platform.pathSeparator}workspace',
  );
  return FileAuthorWorkspaceRepository(
    directory: workspaceDirectory,
    migrationRepository: PreferencesAuthorWorkspaceRepository(preferences),
  );
}
