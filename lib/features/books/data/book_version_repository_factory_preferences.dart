import 'package:dnevnik/features/books/data/preferences_book_version_repository.dart';
import 'package:dnevnik/features/books/domain/book_version_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<BookVersionRepository> createBookVersionRepository(
  SharedPreferences preferences,
) async => PreferencesBookVersionRepository(preferences);
