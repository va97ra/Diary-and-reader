import 'package:dnevnik/features/books/data/preferences_author_workspace_repository.dart';
import 'package:dnevnik/features/books/domain/author_workspace_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AuthorWorkspaceRepository> createAuthorWorkspaceRepository(
  SharedPreferences preferences,
) async => PreferencesAuthorWorkspaceRepository(preferences);
